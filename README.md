# Azure Function App - Exchange Connection and ActiveSync Test

This Azure Function App is a PowerShell script designed to test the connection to an Exchange server and ActiveSync functionality. Test results are returned in JSON format, and in case of a failure, a notification is sent to Teams.

Features

	•	DNS Resolution: Checks DNS resolution of the Exchange server.
	•	Exchange Connection Test: Attempts to connect using Exchange Web Services (EWS).
	•	ActiveSync Connection Test: Tests ActiveSync connection using a specified device ID.
	•	Teams Notifications: Sends a notification to Teams via Webhook API if any test fails.

Requirements

	•	Azure subscription with permission to create an Azure Function App.
	•	Access to an Exchange server.
	•	Teams Incoming Webhook URL.

Environment Variables

The following environment variables should be set in the Application Settings of your Function App for security:

| Variable Name        | Description                                            |
|----------------------|--------------------------------------------------------|
| `ExchangeServer`     | The fully qualified domain name or IP address of the Exchange server |
| `Email`              | The test email address                                 |
| `Password`           | Password for the test email address                    |
| `AsyncUser`          | Username for ActiveSync tests                          |
| `BlobString`         | Connection string for the blob storage                 |
| `NotificationUrl`    | Teams Incoming Webhook URL                             |


PowerShell Script

The PowerShell script running in the Azure Function App uses the above environment variables to perform Exchange and ActiveSync connection tests. Key functions in the script:
	•	Test-ActiveSyncConnection: A helper function to test ActiveSync connectivity.
	•	Invoke-WebRequest: Sends HTTP requests for both Exchange and ActiveSync connections.

JSON Output

Test results are output in JSON format. Example:

{
    "DnsResolution": { "Status": "Success" },
    "ConnectionTest": { "Status": "Failure", "HttpStatusCode": 500, "Message": "Failed to connect to Exchange server." },
    "ActiveSyncTest": { "Status": "Success", "HttpStatusCode": 200, "Message": "ActiveSync connection successful." },
    "Timestamp": "2024-11-09T12:34:56"
}

Teams Notification

If any test result in the JSON output contains "Status": "Failure", a notification is sent to Teams. Example notification:
	•	Text: “Azure Exchange control test….. ews: Failure - AS: Success - DNS: Success”

Usage

After setting up the Azure Function App, you can trigger the script automatically or manually. When triggered via HTTP, the test results are returned as a JSON response.

Steps

	1.	Set Environment Variables: Define the above environment variables in the Configuration section of your Azure Function App.
	2.	Add Teams Webhook URL: Set the NotificationUrl environment variable with your Teams Incoming Webhook URL to receive notifications.
	3.	Run the Function App: You can run it via HTTP trigger or timer trigger.


Additional Information

If you encounter issues with Exchange or ActiveSync connections, verify environment variable values and permissions on your Exchange server.
