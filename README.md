# Xeneta Operations Task

The task is two-fold:

* A practical case of developing a deployable production environment based on a simple application.

* A theoretical case describing a solution to provide secure database access.

You will be expected to present and discuss both solutions.

Some general points:

* **Provide the solution as a public git repository that can easily be cloned by our team.**

* Provide any instructions needed to run the automation solution in `README.md`.

* The configuration file `rates/config.py` has some defaults that will most likely change depending on the solution. It would be beneficial to have a way to more dynamically pass in config values.

* List and describe the tool(s) used, and why they were chosen for the task.

* If you have any questions, please don't hesitate to contact us.

## Practical case: Deployable production environment

### Premise

Provided are two simplified parts of the same application environment: A database dump and an API service. Your task is to automate setting up the production environment in a reliable and testable manner using "infrastructure as code" principles.

The goal is to end up with a limited set of commands that would install and run them using containers. You can use any software that you find suitable for the task. The code should come with instructions on how to run and deploy it to AWS (or any other cloud you are comfortable with).

### Running the database

There’s an SQL dump in `db/rates.sql` that needs to be loaded into a PostgreSQL 13.5 database.

After installing the database, the data can be imported through:

```
createdb rates
psql -h localhost -U postgres < db/rates.sql
```

You can verify that the database is running through:

```
psql -h localhost -U postgres -c "SELECT 'alive'"
```

The output should be something like:

```
 ?column?
----------
 alive
(1 row)
```

### Running the API service

Start from the `rates` folder.

#### 1. Install prerequisites

```
DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y python3-pip
pip install -U gunicorn
pip install -Ur requirements.txt
```

#### 2. Run the application
```
gunicorn -b :3000 wsgi
```

The API should now be running on [http://localhost:3000](http://localhost:3000).

#### 3. Test the application

Get average rates between ports:
```
curl "http://127.0.0.1:3000/rates?date_from=2021-01-01&date_to=2021-01-31&orig_code=CNGGZ&dest_code=EETLL"
```

The output should be something like this:
```
{
   "rates" : [
      {
         "count" : 3,
         "day" : "2021-01-31",
         "price" : 1154.33333333333
      },
      {
         "count" : 3,
         "day" : "2021-01-30",
         "price" : 1154.33333333333
      },
      ...
   ]
}
```

## Case: Secure Database Access

In this section we are seeking high-level answers only (no need to implement anything), and describe your solution appropriately.

We use AWS RDS to host our PostgreSQL database that powers critical data services within Xeneta. Due to compliance requirements, we need to enable end-to-end auditing capability for any operation performed in the database. Along with that, we need an automated solution that rotates database user passwords every 30 days. The database being accessed by both Xeneta internal users and any applications hosted in AWS ECS.
Users will be created on request and a data security personal must approve the request.

Propose a solution that we can implement to achieve the objectives while having zero downtime for the Xeneta applications.

Provide a high-level diagram, along with a few paragraphs describing the choices you've made and what factors you need to take into consideration.

