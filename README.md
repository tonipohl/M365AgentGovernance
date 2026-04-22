# M365 Agent Governance

This repository shows how to automate Microsoft 365 Copilot and agent-related governance tasks by using Microsoft Graph REST API (beta) endpoints from either Azure Logic Apps or PowerShell.

The samples focus on four practical areas:

- Reading Microsoft 365 Copilot usage per user
- Reading Microsoft 365 Copilot usage trends over time
- Reading Microsoft 365 audit log data for Copilot, bots, Power Apps, and Power Automate activity
- Reading the Microsoft 365 Agent Registry catalog

The purpose of the repo is to show the concept of how agent-related management can be automated with Microsoft Graph, using Logic Apps, PowerShell, or similar tooling as the orchestration layer.

## Architecture

All samples use Microsoft Graph REST API beta endpoints.

- Logic Apps are used for workflow orchestration, secret retrieval, polling, storage, and email notification.
- PowerShell is used for direct querying and export.
- Azure Table Storage is used by the Logic Apps as a lightweight persistence layer (but you can use any database system).
- Azure Key Vault is used by the Logic Apps to retrieve the application secret.

## Repository Structure

```text
LogicApps/
  01-CopilotUsageUser.json
  02-CopilotUsageTrend.json
  03-QueryAuditLog.json
PowerShell/
  04-GetAgentRegistry.ps1
  config.json
```

## Logic Apps

### 01-CopilotUsageUser.json

This workflow reads detailed Microsoft 365 Copilot usage per user from Microsoft Graph beta.

Graph endpoint:

```http
GET /beta/reports/getMicrosoft365CopilotUsageUserDetail(period='D7')
```

What it does:

- Retrieves the application secret from Azure Key Vault
- Calls the Copilot usage detail report endpoint with app-only authentication
- Iterates through each returned user record
- Writes or merges the user record into Azure Table Storage
- Calculates inactivity indicators such as whether a user has not used Copilot recently and how many days have passed since last activity
- Builds and sends an HTML email summary to an administrator

Stored data includes:

- User principal name and display name
- Report refresh date
- Last activity date
- Last activity dates per Copilot-enabled workload such as Teams, Word, Excel, PowerPoint, Outlook, OneNote, and Loop
- Derived inactivity flags

This sample shows how to operationalize Copilot usage reporting, persist the results, and notify administrators without building a custom application.

### 02-CopilotUsageTrend.json

This workflow reads trend data for Microsoft 365 Copilot adoption and activity over time.

Graph endpoint:

```http
GET /beta/reports/getMicrosoft365CopilotUserCountTrend(period='ALL')
```

What it does:

- Retrieves the application secret from Azure Key Vault
- Calls the Copilot user count trend report from Microsoft Graph beta
- Parses the nested adoption-by-date payload returned by the report
- Iterates through each day in the returned trend data
- Writes or merges daily trend records into Azure Table Storage
- Sends an email indicating that the trend data has been updated

Stored data includes daily enabled and active user counts for:

- Microsoft Teams
- Word
- PowerPoint
- Outlook
- Excel
- OneNote
- Loop
- Any app
- Copilot Chat

This sample shows the pattern for collecting historical reporting data from Graph and storing it in a form that can later be used for dashboards, trend analysis, or further governance processing.

### 03-QueryAuditLog.json

This workflow creates and monitors a Microsoft 365 audit log query through Microsoft Graph beta and is intended to collect agent-related operational events.

Graph endpoints:

```http
POST /beta/security/auditLog/queries
GET  /beta/security/auditLog/queries/{requestId}
GET  /beta/security/auditLog/queries/{requestId}/records?$top=99999
```

What it does:

- Defines a time range for the audit query
- Retrieves the application secret from Azure Key Vault
- Submits an audit log query to Microsoft Graph beta
- Filters for operations related to Power Apps, Power Automate, bots, and Copilot interactions
- Stores the request metadata in Azure Table Storage
- Polls the query status until processing is complete
- Prepares the records endpoint that can be used to fetch the resulting audit events
- Logs query status and processing state for later review

Included operation filters cover examples such as:

- Create, update, delete, publish, and launch actions for Power Apps
- Create, update, delete, start, and fail actions for flows
- Create, update, delete, publish, and share actions for bots
- Copilot interaction and configured Copilot events

This sample shows the asynchronous audit-query pattern exposed by Graph beta: submit a query, poll for completion, and then retrieve the records.

## PowerShell

### 04-GetAgentRegistry.ps1

This script reads the Microsoft 365 Agent Registry catalog from Microsoft Graph beta and exports the result for analysis.

Graph endpoint:

```http
GET /beta/copilot/admin/catalog/packages
```

What it does:

- Reads tenant and application settings from [PowerShell/config.json](c:\Repo\GitHub\M365AgentGovernance\PowerShell\config.json)
- Connects to Microsoft Graph using the Microsoft Graph PowerShell SDK
- Calls the Microsoft Graph beta endpoint for Copilot admin catalog packages
- Normalizes the package data into a flat PowerShell object model
- Writes the results to the console
- Exports the same data to CSV and Excel files

Exported fields include:

- Package ID
- Display name
- Type
- Short description
- Block status
- Supported hosts
- Last modified date and time
- Publisher
- Availability and deployment scope
- Element types

This sample shows how to discover and inventory agent packages exposed through the Microsoft 365 Copilot admin catalog.

## Prerequisites

### Graph permissions

The exact permissions depend on the sample you run.

- Copilot usage reports require `Reports.Read.All`
- Audit log queries require `AuditLog.Read.All`
- Agent registry access requires `CopilotPackages.Read.All`

For the Logic App workflows, the repository demonstrates app-only authentication against Microsoft Graph by using tenant ID, client ID, and a client secret retrieved from Key Vault.

For the PowerShell sample, authentication is done with the Microsoft Graph PowerShell SDK and the required scope for the catalog endpoint.

### Azure resources used by the Logic Apps

The Logic App samples assume these connected services exist:

- Azure Logic Apps
- Azure Table Storage
- Azure Key Vault
- Office 365 connection for email notification

### PowerShell modules

The PowerShell sample expects these modules:

- `Microsoft.Graph.Authentication`
- `ImportExcel`

## Notes

These samples are intended to show the concept of agent-related management automation with Microsoft Graph.

Typical use cases include:

- Creating lightweight governance workflows without building a full application
- Persisting Copilot usage and trend data for internal reporting
- Automating audit log retrieval for operational review or SIEM ingestion
- Inventorying Microsoft 365 Copilot packages and agents from the catalog
- Using Logic Apps, PowerShell, or other tools as the automation shell around Graph APIs

In short, the repo demonstrates that Microsoft Graph beta can act as the management and reporting interface, while Logic Apps and PowerShell provide practical automation patterns on top of it.

## Samples

- All API examples in this repository use Microsoft Graph beta endpoints.
- Beta endpoints can change, so these samples should be treated as concept and reference implementations.
- Before using these samples in production, review the current Microsoft Graph documentation and validate permissions, response shapes, throttling behavior, and operational limits.



