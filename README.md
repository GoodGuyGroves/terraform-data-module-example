# Terraform "data module" example

## What is a "data" module?
A data module is a module you can use in your terraform code that queries existing infrastructure and returns important information you can then use to base new infrastructure on. For example, you can use the data module to return the name of an ECS cluster to register a new service with or return the name/ARN of a deployment user that you need to attach additional policies to, in order for that deploy user to gain access to the resources you are about to create.

## Why use a data module?
This allows your organisation to have an infrastructure team that handles resources that may be used by multiple other teams (VPC's, container clusters, networking resources, etc) and then allows other teams to use those resources without having to know the details of how they are created. This also allows the infrastructure team to change the way they create those resources without having to update every single terraform file in the organisation.

## Additional considerations
Using this paradigm relies on three very important things:
- Very clear and concise documentation on the existing infrastructure that you want to interface with,
- Well established tagging and naming conventions that you can fall back on in scenarious when you need the name of a resource but don't know what it is called, you can derive the name based on a naming convention or find the resource based on an expected tag, and
- Great documentation of the data module itself. This is important because it allows other teams to know what information they can expect to get back from the data module and how to use it.

## Module design

While creating the data module, it is imperative that you follow the blueprint outlined below. This will ensure that the module is as flexible as possible and won't fall over when you don't provide input for a data source you don't need.

### Using [count](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

When creating data sources, we make heavily use of the `count` meta-argument. If a variable we depend on is set to `null` then we know the user has not provided input for that variable so we set `count = 0`, but if the variable is not `null` then we need to create the resource so we set `count = 1`.

The way we set count is with the terraform ternary operator to create [conditional expressions](https://developer.hashicorp.com/terraform/language/expressions/conditionals). We can check to see if a variable has been set (it is not `null`) and then set the `count` accordingly, like so: `count = var.my_variable != null ? 1 : 0`.

This, however, has a knock-on effect. Now when referencing our data source, we have to reference the index of the resource, eg `data.aws_iam_user.users[0]`. This is not ideal because it means we have to know the index of the resource we want to reference. To get around this, we can use a combination of the terraform [splat operator](https://developer.hashicorp.com/terraform/language/expressions/splat) with the `one()` function. More on that below.

### Declaring [variables](https://developer.hashicorp.com/terraform/language/values/variables)

Using variables is crucial to the functioning of this module but if you do not supply input for a variable then `terraform` will throw an error. Since we don't want to _have to_ supply input for every variable, we have to make them optional. To do this we declare the variable, set `nullable` to `true` and then set the `default` to `null`. Now we can do checks against the variable in question to see if it is `null` or not, if it is `null` then we have not supplied input for that variable and so we know not to try attempt to query for that information.

### Error/Parameter handling

While building this data module, Terraform will throw a lot of errors for variables not being input, referencing resources that haven't been created and so forth. We use the functions below to handle these cases.

#### [try](https://developer.hashicorp.com/terraform/language/functions/try)
> `try` evaluates all of its argument expressions in turn and returns the result of the first one that does not produce any errors.

We use `try` when we are expecting that a resource may exist but it also might not. We will use `try()` on the output, but if it returns an error, we'll instead substitute `null` for the output. For example, when creating an output, we could use `try` like so: `try(data.aws_vpc.this, null)`

#### [coalesce](https://developer.hashicorp.com/terraform/language/functions/coalesce)
> `coalesce` takes any number of arguments and returns the first one that isn't null or an empty string.

This can be used instead of the typical `var.my_varable != null` pattern that is used in conjuction with `count` and the ternary operator. Instead we could do the following: `count = coalesce(var.my_variable, false) ? 1 : 0`

#### [one](https://developer.hashicorp.com/terraform/language/functions/one)
> `one` takes a list, set, or tuple value with either zero or one elements. If the collection is empty, `one` returns `null`. Otherwise, one returns the first element. If there are two or more elements then `one` will return an error.

We use `one()` in conjuction with the [splat operator](https://developer.hashicorp.com/terraform/language/expressions/splat) to ensure we are getting back exactly what we are expecting. Because of using the `count` operator, we have to reference resources using an index but hard-coding the index number is not idea. Instead we use the splat operator like so `data.iam_user.users[*].arn` and then we wrap it with `one()` which ensures only a single element is returned, like so `one(data.iam_user.users[*].arn)`.

## Usage

Following the instructions above, and looking at the example code provided, create your own [terraform module](https://developer.hashicorp.com/terraform/language/modules/develop) and then import it into your terraform code.

To use a module, define a `module {}` block and `source` this repository using the `ssh` form (not HTTPS).
```
module "data" {
  source = "git@github.com:<org>/<repo>.git"
  # pass input based on what values you need
}
```

You should make as many variables as possible optional so that you can supply values depending on what data you need out. For example, if you want to get the ARN for an ECS cluster and nothing else, you will only need to pass in the cluster name to this module.
```
module "data" {
  source = "git@github.com:<org>/<repo>.git"
  ecs_cluster_name = "my-cluster"
}
```

Providing the cluster name may provide more information than you need but you can cherry pick what you want.
```
cluster_subnets = module.data.ecs_cluster.subnets
```

If you then need additional info, for example the ARN of an IAM user, then you would need to provide additional information (perhaps the environment name? eg `dev` or `prod`).
```
module "data" {
  source = "git@github.com:<org>/<repo>.git"
  ecs_cluster_name = "my-cluster"
  acc_env_short = "dev"
}
```