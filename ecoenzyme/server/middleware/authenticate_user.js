import { createClient } from "@supabase/supabase-js";

export async function authenticateUser(req, res, next) {
  const authorization = req.get("authorization") || "";
  const [scheme, accessToken] = authorization.split(" ");

  if (scheme !== "Bearer" || !accessToken) {
    return res.status(401).json({ error: "Sign in to use this service." });
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey =
    process.env.SUPABASE_ANON_KEY ||
    process.env.SUPABASE_KEY;
  if (!supabaseUrl || !supabaseKey) {
    return res.status(503).json({ error: "Authentication service is not configured." });
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data, error } = await supabase.auth.getUser(accessToken);

    if (error || !data.user) {
      return res.status(401).json({ error: "Your session has expired. Please sign in again." });
    }

    req.user = data.user;
    req.supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: `Bearer ${accessToken}` } },
    });
    return next();
  } catch (error) {
    console.error("Request authentication failed:", error.message);
    return res.status(503).json({ error: "Could not verify your session." });
  }
}
