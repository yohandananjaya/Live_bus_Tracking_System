
const rawApiUrl =
    import.meta.env.VITE_API_URL || "http://localhost:5000";

// Remove trailing slashes from API URL
export const API_BASE_URL = rawApiUrl
    .trim()
    .replace(/\/+$/, "");

// Support existing API_URL imports
export const API_URL = API_BASE_URL;
