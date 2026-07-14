// ============================================================
//  C4C STRATEGIC PLANNING — CONFIG
//  Edit the THREE values below, then commit and push.
//  (The anon key is a PUBLIC key by design — it is safe to
//   commit. Row Level Security is what protects the data.
//   Never paste the Supabase "service_role" key here.)
// ============================================================
window.C4C_CONFIG = {
  // 1) Supabase dashboard -> Project Settings -> API -> "Project URL"
  //    Looks like: https://abcdefghijkl.supabase.co
  SUPABASE_URL: "PASTE_YOUR_SUPABASE_PROJECT_URL_HERE",

  // 2) Supabase dashboard -> Project Settings -> API -> Project API keys
  //    -> "anon" / "public" key (a long JWT starting with "eyJ...")
  SUPABASE_ANON_KEY: "PASTE_YOUR_SUPABASE_ANON_PUBLIC_KEY_HERE",

  // 3) The one word board members type to get in. Give them the URL
  //    and this word. Change it before you send the link out.
  PASSPHRASE: "brevard"
};
