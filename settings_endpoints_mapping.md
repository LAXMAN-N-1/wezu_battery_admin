# Settings API Endpoints Audit Report

This document provides a detailed mapping of the "Admin Settings" screens to the backend API endpoints as defined in the OpenAPI specification [https://api1.powerfrill.com/api/v1/openapi.json](https://api1.powerfrill.com/api/v1/openapi.json).

## 1. Summary of Endpoint Connectivity

| Feature Layer | Endpoint Path | Method | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **General Settings** | `/api/v1/admin/settings/general` | GET | ✅ Connected | Used in `SettingsRepository` and `CompanySettingsRepository`. |
| **General Settings** | `/api/v1/admin/settings/general` | POST | ⚠️ Issues | Connected but user reports **400 Error**. |
| **General Settings** | `/api/v1/admin/settings/general/{config_id}` | PATCH | ⚠️ Issues | Connected but user reports **405 Error**. |
| **Feature Flags** | `/api/v1/admin/settings/feature-flags` | GET | ❌ Missing | Repository is currently **Mocked** with local data. |
| **Feature Flags** | `/api/v1/admin/settings/feature-flags/{flag_id}` | PATCH | ❌ Missing | Repository is currently **Mocked**. |
| **API Keys** | `/api/v1/admin/settings/api-keys` | GET | ✅ Connected | Used in `SettingsRepository`. |
| **API Keys** | `/api/v1/admin/settings/api-keys` | POST | ⚠️ Issues | Connected but user reports **400 Error**. |
| **API Keys** | `/api/v1/admin/settings/api-keys/{key_id}` | PATCH | ✅ Connected | Used for toggling status. |
| **API Keys** | `/api/v1/admin/settings/api-keys/{key_id}` | DELETE | ✅ Connected | Works as expected. |
| **System Health** | `/api/v1/admin/settings/system-health` | GET | ✅ Connected | Fully integrated into Mission Control health dashboard. |
| **Webhooks** | `/api/v1/admin/settings/webhooks` | GET/POST | ❌ Missing | Not in OpenAPI spec; Repository uses mock fallback. |

---

## 2. Detailed Issue Analysis

### ⚠️ 400 Bad Request Errors
**Locations:** Create General Setting (POST), Create API Key (POST)

**Potential Causes:**
1. **Extra/Invalid Fields**: 
   - In `createApiKey`, the code sends a `permissions` field as a comma-separated string in the query parameters. However, the OpenAPI spec **does not list `permissions`** as a valid parameter for the `POST` endpoint. This often triggers a `400 Bad Request` in strict backends (like FastAPI).
2. **Body vs Query Mismatch**: 
   - While the OpenAPI spec indicates these parameters are `in: query`, standard REST practices often expect them in the `data` (JSON body). If the backend implementation changed but the spec didn't reflect it, this would cause a 400.
3. **Key collisions**: 
   - For General Settings, trying to `POST` a key that already exists might return a 400 (if the backend enforces unique keys).

### ⚠️ 405 Method Not Allowed Errors
**Location:** Update General Setting (PATCH)

**Potential Causes:**
1. **Method Mismatch**: 
   - The user is calling `PATCH /api/v1/admin/settings/general/{config_id}`. A `405` suggests that either `PATCH` is not supported for this specific subpath (it might actually be `PUT`), or the path itself is slightly different.
2. **Trailing Slashes**: 
   - Sometimes adding/missing a trailing slash causes 405 on some server configurations.
3. **ID Format**: 
   - If `config_id` is passed as a string/invalid type, the routing might fail.

---

## 3. Implementation Discrepancies (Missing Connections)

### Feature Flags (CRITICAL)
- **File**: `lib/features/settings/data/repositories/feature_flag_repository.dart`
- **Status**: **Completely Mocked**.
- **Issue**: The UI is currently interacting with hardcoded list items (`_mockFlags`). It does not call the `/api/v1/admin/settings/feature-flags` endpoint defined in `SettingsRepository`.
- **Recommendation**: Refactor `FeatureFlagRepository` to use the same `ApiClient` pattern as `SettingsRepository` or merge the logic.

### Webhooks
- **File**: `lib/features/settings/data/repositories/settings_repository.dart`
- **Status**: **Mocked in Repository Catch Block**.
- **Issue**: The UI attempts to fetch `/api/v1/admin/settings/webhooks`, but it falls back to mock data because the endpoint likely doesn't exist on the server yet or the path is wrong.

---

## 4. Next Steps & Recommendations

1. **Fix createApiKey**: Remove the `permissions` field from the `POST` request or verify if it should be sent in the JSON body instead of query parameters.
2. **Verify PATCH Method**: Try changing `PATCH` to `PUT` for General Settings update to see if it resolves the 405.
3. **Integrate Real Feature Flags**: Connect the `FeatureFlagRepository` to the `/api/v1/admin/settings/feature-flags` endpoint.
4. **Audit Query Params**: Some backends are transitioning to JSON bodies for POST/PATCH. If query params continue to fail, try moving them to the `data` field in the `ApiClient` calls.
