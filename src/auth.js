import { supabase } from "./supabase.js";

export const configured = !!supabase;

export async function currentUser() {
  const { data } = await supabase.auth.getSession();
  return data.session?.user ?? null;
}
export async function signIn(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}
// Returns true if the user is logged in straight away, false if they must confirm their email first.
export async function signUp(email, password, fullName, accountType = "solo", businessName = "") {
  const { data, error } = await supabase.auth.signUp({ email, password,
    options: { data: { full_name: fullName, account_type: accountType, business_name: businessName } } });
  if (error) throw error;
  return !!data.session;
}
// Student portal sign in (email/password)
export async function signInStudent(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}
// Parent portal sign in (access code)
export async function signInParent(accessCode) {
  // The access code is stored in parent_codes table with a hashed code
  // We'll use a custom RPC or query to verify
  const { data, error } = await supabase.rpc('verify_parent_code', { code: accessCode.toUpperCase() });
  if (error) throw error;
  if (!data?.valid) throw new Error('Invalid access code');
  // Create a session for the parent - we'll use the student's user ID as a reference
  // but we'll store the parent's context in localStorage
  localStorage.setItem('tutordesk.parent_student_id', data.student_id);
  localStorage.setItem('tutordesk.parent_code', accessCode.toUpperCase());
}
export const signOut = () => supabase.auth.signOut();
export const onAuthChange = (cb) => supabase.auth.onAuthStateChange((_event, session) => cb(session?.user ?? null));
