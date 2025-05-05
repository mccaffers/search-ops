# SearchOps

<img align="left" width=100 src="./Logo.png" style="padding-right:10px">

This repository contains the complete open-source iOS and macOS applications for SearchOps. It includes all source code for authenticating and querying ElasticSearch & OpenSearch instances, along with a local encrypted datastore using Realm.

[![Build](https://github.com/mccaffers/SearchOps/actions/workflows/swift.yml/badge.svg)](https://github.com/mccaffers/SearchOps/actions/workflows/swift.yml) [![Coverage](https://sonarcloud.io/api/project_badges/measure?project=mccaffers_SearchOps&metric=coverage)](https://sonarcloud.io/summary/new_code?id=mccaffers_SearchOps) [![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=mccaffers_SearchOps&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=mccaffers_SearchOps) [![Technical Debt](https://sonarcloud.io/api/project_badges/measure?project=mccaffers_SearchOps&metric=sqale_index)](https://sonarcloud.io/summary/new_code?id=mccaffers_SearchOps) [![Maintainability Rating](https://sonarcloud.io/api/project_badges/measure?project=mccaffers_SearchOps&metric=sqale_rating)](https://sonarcloud.io/summary/new_code?id=mccaffers_SearchOps)

## Supports

- ElasticSearch version 6.0 and above
- Opensearch version 1.0 and above

## Apple App Store

Available on the Apple App Store for iOS and macOS platforms

<a href="https://apps.apple.com/us/app/search-ops/id6453696339?platform=iphone"><img width=18% src="./AppStore.svg"></a>

## Screenshots

<img align="left" width=25% src="./Screenshots/listview.png" style="padding:10px">
<img align="left" width=25% src="./Screenshots/tableview.png" style="padding:10px">
<img align="left" width=25% src="./Screenshots/document.png" style="padding:10px">

<br clear="left"/>

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
* On build tests with Github Actions with Sonarcloud analysis
