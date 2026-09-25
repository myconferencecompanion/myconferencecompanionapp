import { createFileRoute, Link, redirect } from "@tanstack/react-router";
import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { lovable } from "@/integrations/lovable";
import { useAuth, stashPendingRoleCode } from "@/lib/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { toast } from "sonner";
import { EVENT_CONFIG } from "@/lib/event-config";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: `Sign in — ${EVENT_CONFIG.name} ${EVENT_CONFIG.year}` },
      { name: "description", content: "Sign in or create your account for the conference companion app." },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const { user, loading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [roleCode, setRoleCode] = useState("");
  const [signInRoleCode, setSignInRoleCode] = useState("");
  const [busy, setBusy] = useState(false);

  if (!loading && user) {
    throw redirect({ to: "/home" });
  }

  async function signIn(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    if (signInRoleCode.trim()) stashPendingRoleCode(signInRoleCode);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Welcome back!");
  }

  async function signUp(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    if (roleCode.trim()) stashPendingRoleCode(roleCode);
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/home`,
        data: { full_name: fullName },
      },
    });
    setBusy(false);
    if (error) return toast.error(error.message);
    toast.success("Account created! Check your inbox to confirm your email.");
  }

  async function signInWithGoogle() {
    setBusy(true);
    const result = await lovable.auth.signInWithOAuth("google", {
      redirect_uri: window.location.origin + "/home",
    });
    if (result.error) {
      setBusy(false);
      toast.error(result.error.message || "Google sign-in failed");
      return;
    }
    if (result.redirected) return;
    // Tokens already set
    window.location.href = "/home";
  }

  return (
    <div className="flex min-h-screen flex-col bg-brand-gradient px-5 py-10 text-white">
      <div className="mx-auto w-full max-w-sm">
        <div className="mb-8 text-center">
          <p className="text-xs font-medium uppercase tracking-[0.25em] text-white/80">
            {EVENT_CONFIG.dates}
          </p>
          <h1 className="mt-2 text-3xl font-bold leading-tight">
            {EVENT_CONFIG.name} <span className="text-accent">{EVENT_CONFIG.year}</span>
          </h1>
          <p className="mt-2 text-sm text-white/70">{EVENT_CONFIG.tagline}</p>
        </div>

        <Card className="p-5">
          <Tabs defaultValue="signin">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="signin">Sign in</TabsTrigger>
              <TabsTrigger value="signup">Sign up</TabsTrigger>
            </TabsList>

            <TabsContent value="signin" className="mt-5 space-y-4">
              <form onSubmit={signIn} className="space-y-3">
                <div className="space-y-1.5">
                  <Label htmlFor="si-email">Email</Label>
                  <Input id="si-email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="si-pass">Password</Label>
                  <Input id="si-pass" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="si-code">
                    Role code <span className="text-muted-foreground">(optional — staff only)</span>
                  </Label>
                  <Input
                    id="si-code"
                    value={signInRoleCode}
                    onChange={(e) => setSignInRoleCode(e.target.value)}
                    placeholder="e.g. NSE-KITCHEN-3046"
                    autoCapitalize="characters"
                  />
                </div>
                <Button type="submit" className="w-full" disabled={busy}>
                  {busy ? "Signing in…" : "Sign in"}
                </Button>
              </form>
            </TabsContent>

            <TabsContent value="signup" className="mt-5 space-y-4">
              <form onSubmit={signUp} className="space-y-3">
                <div className="space-y-1.5">
                  <Label htmlFor="su-name">Full name</Label>
                  <Input id="su-name" required value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Chinedu Okafor" />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="su-email">Email</Label>
                  <Input id="su-email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="su-pass">Password</Label>
                  <Input id="su-pass" type="password" required minLength={6} value={password} onChange={(e) => setPassword(e.target.value)} />
                </div>
                <div className="space-y-1.5">
                  <Label htmlFor="su-code">
                    Role code <span className="text-muted-foreground">(optional — staff only)</span>
                  </Label>
                  <Input
                    id="su-code"
                    value={roleCode}
                    onChange={(e) => setRoleCode(e.target.value)}
                    placeholder="e.g. NSE-COMMS-4837"
                    autoCapitalize="characters"
                  />
                  <p className="text-[11px] text-muted-foreground">
                    Leave blank to join as an attendee. Codes are applied on first sign-in.
                  </p>
                </div>
                <Button type="submit" className="w-full" disabled={busy}>
                  {busy ? "Creating account…" : "Create account"}
                </Button>
              </form>
            </TabsContent>
          </Tabs>

          <div className="my-5 flex items-center gap-3 text-xs text-muted-foreground">
            <div className="h-px flex-1 bg-border" />
            or
            <div className="h-px flex-1 bg-border" />
          </div>

          <Button
            variant="outline"
            className="w-full gap-2"
            onClick={signInWithGoogle}
            disabled={busy}
          >
            <GoogleIcon />
            Continue with Google
          </Button>
        </Card>

        <p className="mt-6 text-center text-xs text-white/60">
          By signing in you agree to the conference code of conduct.
        </p>
        <p className="mt-2 text-center text-xs">
          <Link to="/" className="text-white/70 hover:text-white">← Back</Link>
        </p>
      </div>
    </div>
  );
}

function GoogleIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4" aria-hidden>
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.19 3.32v2.77h3.54c2.07-1.9 3.29-4.71 3.29-8.1Z" />
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.54-2.77c-.98.66-2.23 1.06-3.74 1.06-2.87 0-5.3-1.94-6.17-4.55H2.18v2.86A11 11 0 0 0 12 23Z" />
      <path fill="#FBBC05" d="M5.83 14.08A6.6 6.6 0 0 1 5.47 12c0-.72.12-1.42.36-2.08V7.06H2.18A11 11 0 0 0 1 12c0 1.77.42 3.44 1.18 4.94l3.65-2.86Z" />
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.07.56 4.21 1.65l3.15-3.15C17.45 2.09 14.97 1 12 1A11 11 0 0 0 2.18 7.06l3.65 2.86C6.7 7.32 9.13 5.38 12 5.38Z" />
    </svg>
  );
}
