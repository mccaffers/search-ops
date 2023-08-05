# SearchOps

<img align="left" width=100 src="./Logo.png" style="padding-right:10px">

This Swift Package contains the business logic for the SearchOps iOS application. Supports the authentication and querying of ElasticSearch & OpenSearch. Manages the local data store for credentials.

<br clear="left"/>

## Apple App Store

The full application with the presentation layer (SwiftUI) is available on the Apple App Store.

[![Available on App Store](./AppStore.svg)](https://apps.apple.com/us/app/search-ops/id6453696339)

## Supports

- ElasticSearch version 6.0 and above
- Opensearch version 1.0 and above

## Features

Query ElasticSearch and OpenSearch clusters
* Free text strings, using compounds (AND/OR) and date ranges 
* View results as documents or in a table
* Easily switch between hosts, indexes and filter on mapped data types

Support ElasticSearch (v5.0 and above) and OpenSearch (v1.0 and above)
* /_mapping
* /_search
* /_aliases

Authentication:
* Connection using a CloudID from Elastic.co or a direct host connection
* Authenticate with Username/Password, Auth Token, API Token or API Key
* Readonly access only. Requires a user with Viewer and Monitoring User

Privacy & Transparency:
* Open Source business logic on Github
* No tracking or analytics
* Uses a local on device database (Realm) with encryption on

Local Database
* This package utilities a local Realm Database (https://github.com/realm/realm-swift). By default, this packages enables encryption and disabled metrics.

Testing
* Swift testing with various responses `./Tests/Resources`
* Nightly tests with Github Actions
* [![Nightly Test](https://github.com/mccaffers/SearchOps/actions/workflows/swift.yml/badge.svg)](https://github.com/mccaffers/SearchOps/actions/workflows/swift.yml)

## Project Breakdown

```bash
 └── SearchOps # Swift Package   
    ├── Sources
│   └── SearchOps/
│       ├── Constants.swift
│       ├── DataManagers/ # Data Store for Hosts, Filters and Logs
│       │   ├── FilterHistoryDataManager.swift
│       │   ├── HostsDataManager.swift
│       │   ├── LogDataManager.swift
│       │   ├── RealmManager.swift
│       │   └── SearchSettingsManager.swift
│       ├── Functions/ # Request Logic for Searching, Indexes and Mapping
│       │   ├── Fields.swift
│       │   ├── IndexMap.swift
│       │   ├── Indicies.swift
│       │   ├── Request.swift
│       │   ├── Results.swift
│       │   └── Search.swift
│       ├── Models/ # Several data models to store responses
│       ├── SearchOps.swift
│       └── Utilities/ # Various tools to build authentication, handle dates and JSON
└── Tests/
```
