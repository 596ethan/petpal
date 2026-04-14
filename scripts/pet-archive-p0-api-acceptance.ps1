param(
  [string]$ApiBaseUrl = "http://127.0.0.1:18080",
  [string]$Phone = "13800000001",
  [string]$Password = "123456"
)

$ErrorActionPreference = "Stop"

function ConvertTo-JsonBody {
  param([object]$Body)
  if ($null -eq $Body) {
    return $null
  }
  return ($Body | ConvertTo-Json -Depth 8)
}

function Read-ErrorBody {
  param([System.Net.WebResponse]$Response)
  if ($null -eq $Response) {
    return ""
  }
  $stream = $Response.GetResponseStream()
  if ($null -eq $stream) {
    return ""
  }
  $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
  return $reader.ReadToEnd()
}

function Invoke-PetPalJson {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null,
    [string]$Token = "",
    [int]$ExpectedStatus = 200,
    [int]$TimeoutSec = 15
  )

  $base = $ApiBaseUrl.TrimEnd("/")
  $uri = "$base$Path"
  $headers = @{}
  if ($Token.Length -gt 0) {
    $headers["Authorization"] = "Bearer $Token"
  }

  $jsonBody = ConvertTo-JsonBody -Body $Body
  try {
    if ($null -eq $jsonBody) {
      $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $headers -TimeoutSec $TimeoutSec
    } else {
      $response = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers $headers -ContentType "application/json; charset=utf-8" -Body $jsonBody -TimeoutSec $TimeoutSec
    }
    $statusCode = [int]$response.StatusCode
    $content = [string]$response.Content
  } catch {
    $webResponse = $_.Exception.Response
    if ($null -eq $webResponse) {
      throw "Request failed before receiving an HTTP response: $Method $uri. $($_.Exception.Message)"
    }
    $statusCode = [int]$webResponse.StatusCode
    $content = Read-ErrorBody -Response $webResponse
  }

  $parsed = $null
  if ($content.Trim().Length -gt 0) {
    $parsed = $content | ConvertFrom-Json
  }

  if ($statusCode -ne $ExpectedStatus) {
    throw "Expected HTTP $ExpectedStatus but got $statusCode for $Method $Path. Body: $content"
  }

  return [pscustomobject]@{
    StatusCode = $statusCode
    Body = $parsed
  }
}

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )
  if (-not $Condition) {
    throw "ASSERT FAILED: $Message"
  }
}

function Assert-OkEnvelope {
  param(
    [object]$Response,
    [string]$Label
  )
  Assert-True ($Response.Body.code -eq "OK") "$Label should return code OK"
}

$stamp = Get-Date -Format "yyyyMMddHHmmss"
$mainName = "P0-Acceptance-Pet-$stamp"
$updatedName = "$mainName-Updated"
$deleteName = "P0-Acceptance-Delete-$stamp"

Write-Host "Pet Archive P0 API acceptance"
Write-Host "API base: $ApiBaseUrl"
Write-Host "Phone: $Phone"

$login = Invoke-PetPalJson -Method "POST" -Path "/api/user/login" -Body @{
  phone = $Phone
  password = $Password
}
Assert-OkEnvelope $login "login"
$token = [string]$login.Body.data.tokens.accessToken
Assert-True ($token.Length -gt 0) "login should return accessToken"
Write-Host "[PASS] login"

$createPet = Invoke-PetPalJson -Method "POST" -Path "/api/pet" -Token $token -Body @{
  name = $mainName
  species = "DOG"
  breed = "Border Collie"
  gender = "MALE"
  birthday = "2024-04-01"
  weight = 8.6
  neutered = $false
}
Assert-OkEnvelope $createPet "create pet"
$petId = [int64]$createPet.Body.data.id
Assert-True ($createPet.Body.data.name -eq $mainName) "created pet name should match"
Write-Host "[PASS] create pet id=$petId"

$updatePet = Invoke-PetPalJson -Method "PUT" -Path "/api/pet/$petId" -Token $token -Body @{
  name = $updatedName
  weight = 9.1
}
Assert-OkEnvelope $updatePet "partial update pet"
Assert-True ($updatePet.Body.data.name -eq $updatedName) "updated name should match"
Assert-True ($updatePet.Body.data.breed -eq "Border Collie") "partial update should preserve breed"
Assert-True ($updatePet.Body.data.species -eq "DOG") "partial update should preserve species"
Assert-True ($updatePet.Body.data.gender -eq "MALE") "partial update should preserve gender"
Assert-True ([double]$updatePet.Body.data.weight -eq 9.1) "partial update should change weight"
Write-Host "[PASS] partial update"

$healthOne = Invoke-PetPalJson -Method "POST" -Path "/api/pet/$petId/health" -Token $token -Body @{
  recordType = "CHECKUP"
  title = "P0 Health Check"
  description = "Device acceptance health record"
  recordDate = "2026-04-14"
  nextDate = "2026-05-14"
}
Assert-OkEnvelope $healthOne "add first health record"
$healthOneId = [int64]$healthOne.Body.data.id
Write-Host "[PASS] add health record id=$healthOneId"

$healthTwo = Invoke-PetPalJson -Method "POST" -Path "/api/pet/$petId/health" -Token $token -Body @{
  recordType = "MEDICATION"
  title = "P0 Same Day Second"
  description = "Sort acceptance record"
  recordDate = "2026-04-14"
}
Assert-OkEnvelope $healthTwo "add second health record"
$healthTwoId = [int64]$healthTwo.Body.data.id

$healthList = Invoke-PetPalJson -Method "GET" -Path "/api/pet/$petId/health" -Token $token
Assert-OkEnvelope $healthList "list health records"
$healthRows = @($healthList.Body.data)
$healthOneIndex = -1
$healthTwoIndex = -1
for ($i = 0; $i -lt $healthRows.Count; $i++) {
  if ([int64]$healthRows[$i].id -eq $healthOneId) {
    $healthOneIndex = $i
  }
  if ([int64]$healthRows[$i].id -eq $healthTwoId) {
    $healthTwoIndex = $i
  }
}
Assert-True ($healthOneIndex -ge 0) "first health record should appear in list"
Assert-True ($healthTwoIndex -ge 0) "second health record should appear in list"
Assert-True ($healthTwoIndex -lt $healthOneIndex) "same-day health record with larger id should sort first"
Write-Host "[PASS] health list sorted by recordDate desc, id desc"

$vaccine = Invoke-PetPalJson -Method "POST" -Path "/api/pet/$petId/vaccine" -Token $token -Body @{
  vaccineName = "P0 Rabies Vaccine"
  vaccinatedAt = "2026-04-14"
  nextDueAt = "2027-04-14"
  hospital = "P0 Acceptance Vet"
}
Assert-OkEnvelope $vaccine "add vaccine record"
$vaccineId = [int64]$vaccine.Body.data.id

$vaccineList = Invoke-PetPalJson -Method "GET" -Path "/api/pet/$petId/vaccine" -Token $token
Assert-OkEnvelope $vaccineList "list vaccine records"
$vaccineRows = @($vaccineList.Body.data)
$createdVaccine = $vaccineRows | Where-Object { [int64]$_.id -eq $vaccineId } | Select-Object -First 1
Assert-True ($null -ne $createdVaccine) "created vaccine record should appear in list"
Assert-True ($createdVaccine.vaccineName -eq "P0 Rabies Vaccine") "vaccine name should match"
Write-Host "[PASS] add and list vaccine record"

$deletePet = Invoke-PetPalJson -Method "POST" -Path "/api/pet" -Token $token -Body @{
  name = $deleteName
  species = "CAT"
  gender = "UNKNOWN"
}
Assert-OkEnvelope $deletePet "create delete-target pet"
$deletePetId = [int64]$deletePet.Body.data.id

$deleteResponse = Invoke-PetPalJson -Method "DELETE" -Path "/api/pet/$deletePetId" -Token $token
Assert-OkEnvelope $deleteResponse "soft delete pet"

$petList = Invoke-PetPalJson -Method "GET" -Path "/api/pet/list" -Token $token
Assert-OkEnvelope $petList "list pets after delete"
$deletedStillVisible = @($petList.Body.data) | Where-Object { [int64]$_.id -eq $deletePetId } | Select-Object -First 1
Assert-True ($null -eq $deletedStillVisible) "soft-deleted pet should not be visible in list"

$deletedDetail = Invoke-PetPalJson -Method "GET" -Path "/api/pet/$deletePetId" -Token $token -ExpectedStatus 404
Assert-True ($deletedDetail.Body.code -eq "PET_NOT_FOUND") "deleted pet detail should return PET_NOT_FOUND"
Write-Host "[PASS] soft delete visibility and PET_NOT_FOUND"

Write-Host ""
Write-Host "API acceptance completed."
Write-Host "Main acceptance pet left for phone inspection: id=$petId name=$updatedName"
