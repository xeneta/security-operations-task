Part 1:

This terraform project was tested locally in a MacBook Pro (Monterey v12.6) using Terraform v1.2.5 
and Docker engine v20.10.12.

Please ensure that you have the docker running on your machine (I often shut it down due to resources) as Terraform plan will fail without it running in the background.


Here are the steps to spin up the container environment with the api server consuming data from postgresl 13 
in the same container. 

After docker daemon bootstraps, cd to the root of the project, and run the following commands:

terraform init
terraform plan
terraform apply -auto-approve

Running these commands shall create and provision a docker container which has a postgres populated with data from the
sql dump and api server.
psql -h localhost -U postgres -c "SELECT 'alive'" and the curl command generated expected results

Notice that after running the last command, the console will stay active.Kill it by entering
CTRL+C, which will not affect the functionality of the running container.

Deployment to AWS will require a permissible AWS role and the logic for product is likely quite different 
from that for local, mainly because of the following reasons:
1. For the local environment, the postgres and api servers run in the same container as suggested by the requirements of 
the challenge. In product, the db and api will run in separate containers with images.
2. For local, the docker image comes from a ready-made postgres image with custom logic for the
   api server. For product, there will be separate images likely from a registry.
3. In local, a docker provider is used. In prod, the same provider can be used. Some docker provisioner resources, however, 
can only run in a container cluster, so local has to use a workaround for the provisioning of the api server.
4. As far as I can see, the security requirements for prod can be pretty expensive to implement in local, if not impractical.

On the other hand, the vast majority of the deployment for different AWS environments dev, stage, prod, for example, shall
be sharable as terraform modules, with environmental differences passed as deploy time terraform variables.

The Dockerfile for this local deployment contains hardcoded environment variables for DB credentials. For AWS deployment, 
they will be provided as environment variables in the task definition for the DB.

This commit has not addressed a potential weakness that DB credentials are hardcoded in config.py.
It is not addressed because the local solution will be quite different from an aws solution, while credential management
is a key component of the next part of the challenge.

Part 2:

ECS is a solid service which will be the focus of this second part of the discussion. Before I go further, I want to 
briefly mention that EKS, although more complex, has two notable merits in my opinion, one of which is that the code to
deploy and provision a Kubernetes cluster is largely the same across common public clouds, while ECS is locked to AWS.
Usually such locking is not an issue, but I did participate in one re-clouding project.
Arguably, another merit is tooling is slightly better and tends to offer more options. With helm, for example, 
installing software package in EKS pods could be easier than in ECS containers.

On the other hand, if we do not envision future cloud migration and the staple docker images do not need to complex 
provisioning and customization, ECS is a great fit, enjoying smooth integration of AWS security components.

Below is a description of one possible solution. Every component described can be provisioned via terraform scripts.

terraform script layout:
   root directory
      -lib # for resuable logic
         -module 1
         -module 2
      -dev
         main.tf with aws provider and a remote backend. It will mostly contain invocation of modules defined under lib.
         variables
         outputs
      -stage # similar to dev. The significant differences will be in the variables file.
      -prod # similar to dev. The significant differences will be in the variables file.

1. CloudTrail can be used to audit traffic to and from the DB containers, the latter which will be created with logging
through CloudTrail.
2. IAM policies will be created for DB access.
3. IAM roles will be created for users and applications for DB access.
4. An AWS secrete manager can be used for DB access credentials. It can be configured to transparently rotate secrets every 
30 days, without any downtime if apps in ECS are configured to read credentials from the manager. 
The manager can be configured with CloudTrail auditing as well.
5. ECR or a private image registry can be used to store custom docker images.

A downside of this design is it uses many managed services which are relatively costly. Depending on the load on the ECS
cluster, we may not need some of such services. In that case, we can come up with some custom components which are not
too hard to build and maintain.

A diagram for the architecture is included in another file.

Docker push -> ECR or a preferred image registry -> ECS postgres container <- CloudTrail
                                                               ^
                                                               |
                                                      Secret manager with
                                                      30 day secret rotation
                                                               ^
                                                               |
                                                      IAM policies for
                                                      DB access
                                                               ^
                                                               |
                                                      IAM roles/groups to users and
                                                      apps for DB access