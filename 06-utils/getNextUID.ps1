# ============================================================================================
# Script Name : getNextUID.ps1
# Description : Retrieves the next available UID number from the RStudio cluster service.
# ============================================================================================

# --------------------------------------------------------------------------------------------
# Service Endpoint
# - The endpoint returns a JSON payload containing UID/GID allocation information.
# - Example JSON Response:
#   {
#       "max_gidNumber": 10005,
#       "max_uidNumber": 10004,
#       "next_gidNumber": 10006,
#       "next_uidNumber": 10005
#   }
# --------------------------------------------------------------------------------------------

$uri = "http://rstudio.mikecloud.com/nextids"

try {
    # ----------------------------------------------------------------------------------------
    # Invoke the REST API
    # - Sends an HTTP GET request to the specified endpoint.
    # - Automatically parses the JSON response into a PowerShell object.
    # ----------------------------------------------------------------------------------------
    $response = Invoke-RestMethod -Uri $uri -Method Get

    # ----------------------------------------------------------------------------------------
    # Output Result
    # - Extracts the "next_uidNumber" property from the response object.
    # - Formats the output message to highlight the UID value.
    # ----------------------------------------------------------------------------------------
    Write-Output ("NOTE: Next uidNumber is {0}" -f $response.next_uidNumber)
}
catch {
    # ----------------------------------------------------------------------------------------
    # Error Handling
    # - Catches and reports any failures during the REST API call (e.g., connectivity issues,
    #   invalid JSON response, or permission problems).
    # ----------------------------------------------------------------------------------------
    Write-Error "ERROR: Failed to call $uri : $_"
}
