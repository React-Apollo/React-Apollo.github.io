---
title: Primsa-YAML 配置文件
date: 2018-02-19 08:05:43
categories: 技术备忘
tags: [Graphcool,Prisma]
---

{{TOC}}

##  example

每个 Prisma 服务包括一个配置文件

```
# REQUIRED
# `my-demo-app` is the name of this Prisma service.
service: my-demo-app

# REQUIRED
# This service is based on the type definitions in the two files
# `database/types.graphql` and `database/enums.graphql`
datamodel:
  - database/types.graphql
  - database/enums.graphql

# OPTIONAL
# The service will be deployed to the `local` cluster.
# Note that if you leave out this option, you will be
# asked which cluster to deploy to, and your decision
# will be persisted here.
cluster: local

# REQUIRED
# This service will be deployed to the `dev` stage.
stage: dev

# OPTIONAL (default: false)
# Whether authentication is required for this service
# is based on the value of the `PRISMA_DISABLE_AUTH`
# environment variable.
disableAuth: ${env:PRISMA_DISABLE_AUTH}

# OPTIONAL
# If your Prisma service requires authentication, this is the secret for creating JWT tokens.
secret: 

# OPTIONAL
# Path where the full GraphQL schema will be written to
# after deploying. Note that it is generated based on your
# data model.
schema: schemas/prisma.graphql

# OPTIONAL
# This service has one event subscription configured. The corresponding
# subscription query is located in `database/subscriptions/welcomeEmail.graphql`.
# When the subscription fires, the specified `webhook` is invoked via HTTP.
subscriptions:
  sendWelcomeEmail:
    query: database/subscriptions/sendWelcomeEmail.graphql
    webhook:
      url: https://${self.custom:serverlessEndpoint}/sendWelcomeEmail
      headers:
        Authorization: ${env:MY_ENDPOINT_SECRET}

# OPTIONAL
# Points to a `.graphql` file containing GraphQL operations that will be
# executed when initially deploying a service.
seed:
  import: database/seed.graphql

# OPTIONAL
# This service only defines one custom variable that's referenced in
# the `webhook` of the `subscription`
custom:
  serverlessEndpoint: https://bcdeaxokbj.execute-api.eu-west-1.amazonaws.com/dev
```

文件结构如下:

```
.
├── prisma.yml
├── database
│   ├── subscriptions
│   │   └── welcomeEmail.graphql
│   ├── types.graphql
│   └── enums.graphql
└── schemas
    └── prisma.graphql
```

## YAML 文件结构
/Applications/Chromium.app/Contents/MacOS/Chromium


