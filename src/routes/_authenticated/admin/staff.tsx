import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { initials } from "@/lib/format";
import { toast } from "sonner";
import { Copy, KeyRound, Search, ShieldCheck, UserPlus } from "lucide-react";

export const Route = createFileRoute("/_authenticated/admin/staff")({
  beforeLoad: async () => {
    // Super admins and plain admins manage staff; sub-role staff do not.
    const { data } = await supabase.auth.getUser();
    if (!data.user) return;
    const { data: roles } = await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", data.user.id);
    const has = roles?.some((r) => r.role === "admin" || r.role === "super_admin");
    if (!has) throw new Error("Not allowed");
  },
  component: StaffPeoplePage,
});

const ROLE_LABEL: Record<string, string> = {
  attendee: "Attendee",
  admin: "Admin",
  super_admin: "Super Admin",
  front_desk: "Front Desk",
  kitchen: "Kitchen",
  program: "Program",
  logistics: "Logistics",
  comms: "Comms",
};

function StaffPeoplePage() {
  return (
    <div className="space-y-6">
      <StaffCodes />
      <PeopleDirectory />
    </div>
  );
}

/* ------------------------------ staff codes ------------------------------ */

function StaffCodes() {
  const qc = useQueryClient();
  const [newCode, setNewCode] = useState("");
  const [newRole, setNewRole] = useState("front_desk");
  const [newLabel, setNewLabel] = useState("");

  const { data: codes = [] } = useQuery({
    queryKey: ["admin-signup-codes"],
    queryFn: async () => {
      const { data } = await supabase
        .from("signup_codes")
        .select("*")
        .order("is_active", { ascending: false })
        .order("created_at", { ascending: false });
      return data ?? [];
    },
  });

  const create = useMutation({
    mutationFn: async () => {
      const code = newCode.trim().toUpperCase();
      if (!/^[A-Z0-9-]{6,40}$/.test(code)) {
        throw new Error("Code: letters, numbers and dashes only (6+ chars)");
      }
      const { error } = await supabase.from("signup_codes").insert({
        code,
        role: newRole,
        label: newLabel.trim() || ROLE_LABEL[newRole],
        is_active: true,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("Code created");
      setNewCode("");
      setNewLabel("");
      qc.invalidateQueries({ queryKey: ["admin-signup-codes"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const toggle = useMutation({
    mutationFn: async ({ code, is_active }: { code: string; is_active: boolean }) => {
      const { error } = await supabase
        .from("signup_codes")
        .update({ is_active })
        .eq("code", code);
      if (error) throw error;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin-signup-codes"] });
      toast.success("Saved");
    },
    onError: (e: Error) => toast.error(e.message),
  });

  async function copy(code: string) {
    try {
      await navigator.clipboard.writeText(code);
      toast.success(`Copied ${code}`);
    } catch {
      toast.error("Could not copy — long-press to select");
    }
  }

  return (
    <section>
      <div className="mb-2 flex items-center gap-2">
        <KeyRound className="h-4 w-4 text-primary" />
        <h3 className="text-sm font-bold uppercase tracking-wide">Staff signup codes</h3>
      </div>
      <p className="mb-3 text-xs text-muted-foreground">
        Anyone who signs up with a code (More → Redeem role code, or on the sign-up
        form) instantly gets that staff role and its control center.
      </p>

      <div className="space-y-2">
        {codes.map((c) => (
          <Card key={c.code} className="flex items-center gap-3 border-0 p-3 shadow-card">
            <div className="min-w-0 flex-1">
              <p className="truncate font-mono text-sm font-bold">{c.code}</p>
              <p className="text-xs text-muted-foreground">
                {c.label} · {ROLE_LABEL[c.role] ?? c.role}
              </p>
            </div>
            <Badge
              className={
                c.is_active
                  ? "bg-success-soft text-success-foreground"
                  : "bg-muted text-muted-foreground"
              }
            >
              {c.is_active ? "active" : "off"}
            </Badge>
            <Button size="icon" variant="outline" className="h-8 w-8 shrink-0" onClick={() => void copy(c.code)} aria-label={`Copy ${c.code}`}>
              <Copy className="h-3.5 w-3.5" />
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="shrink-0"
              onClick={() => toggle.mutate({ code: c.code, is_active: !c.is_active })}
            >
              {c.is_active ? "Disable" : "Enable"}
            </Button>
          </Card>
        ))}
      </div>

      <Card className="mt-3 space-y-3 border-0 p-4 shadow-card">
        <p className="flex items-center gap-2 text-sm font-semibold">
          <UserPlus className="h-4 w-4 text-primary" /> Create another code
        </p>
        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-1.5">
            <Label htmlFor="nc-code">Code</Label>
            <Input
              id="nc-code"
              value={newCode}
              onChange={(e) => setNewCode(e.target.value)}
              placeholder="NSE-USHERS-A"
              autoCapitalize="characters"
            />
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="nc-role">Role</Label>
            <select
              id="nc-role"
              value={newRole}
              onChange={(e) => setNewRole(e.target.value)}
              className="flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
            >
              {(["front_desk", "kitchen", "program", "logistics", "comms"] as const).map((r) => (
                <option key={r} value={r}>
                  {ROLE_LABEL[r]}
                </option>
              ))}
            </select>
          </div>
        </div>
        <div className="space-y-1.5">
          <Label htmlFor="nc-label">Label (optional)</Label>
          <Input
            id="nc-label"
            value={newLabel}
            onChange={(e) => setNewLabel(e.target.value)}
            placeholder="Gate A Ushers"
          />
        </div>
        <Button onClick={() => create.mutate()} disabled={create.isPending || !newCode.trim()} className="w-full">
          {create.isPending ? "Creating…" : "Create code"}
        </Button>
      </Card>
    </section>
  );
}

/* ---------------------------- people directory --------------------------- */

type Person = {
  id: string;
  display_name: string | null;
  title: string | null;
  company: string | null;
  networking_opt_in: boolean;
  created_at: string | null;
  roles: string[];
};

function PeopleDirectory() {
  const [q, setQ] = useState("");

  const { data: people = [], isLoading } = useQuery({
    queryKey: ["admin-people"],
    queryFn: async (): Promise<Person[]> => {
      const [profRes, rolesRes] = await Promise.all([
        supabase.from("profiles").select("*").order("created_at", { ascending: false }),
        supabase.from("user_roles").select("user_id, role"),
      ]);
      const rolesByUser = new Map<string, string[]>();
      for (const r of rolesRes.data ?? []) {
        const list = rolesByUser.get(r.user_id) ?? [];
        list.push(r.role);
        rolesByUser.set(r.user_id, list);
      }
      return (profRes.data ?? []).map((p) => ({
        id: p.id,
        display_name: p.display_name,
        title: p.title,
        company: p.company,
        networking_opt_in: p.networking_opt_in,
        created_at: p.created_at,
        roles: rolesByUser.get(p.id) ?? [],
      }));
    },
  });

  const filtered = people.filter((p) => {
    const s = q.trim().toLowerCase();
    if (!s) return true;
    return (
      (p.display_name ?? "").toLowerCase().includes(s) ||
      (p.company ?? "").toLowerCase().includes(s) ||
      (p.title ?? "").toLowerCase().includes(s) ||
      p.roles.some((r) => (ROLE_LABEL[r] ?? r).toLowerCase().includes(s))
    );
  });

  return (
    <section>
      <div className="mb-2 flex items-center gap-2">
        <ShieldCheck className="h-4 w-4 text-primary" />
        <h3 className="text-sm font-bold uppercase tracking-wide">
          Registered people ({people.length})
        </h3>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search name, company, role…"
          className="pl-9"
        />
      </div>

      {isLoading ? (
        <p className="mt-4 text-sm text-muted-foreground">Loading…</p>
      ) : (
        <div className="mt-3 space-y-2">
          {filtered.map((p) => (
            <Card key={p.id} className="border-0 p-3 shadow-card">
              <div className="flex items-center gap-3">
                <Avatar className="h-10 w-10">
                  <AvatarFallback>{initials(p.display_name || "?")}</AvatarFallback>
                </Avatar>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold">{p.display_name ?? "Unnamed"}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {[p.title, p.company].filter(Boolean).join(" · ") || "—"}
                  </p>
                </div>
                <div className="flex shrink-0 flex-wrap justify-end gap-1">
                  {p.roles.length === 0 && <Badge variant="outline">attendee</Badge>}
                  {p.roles
                    .filter((r) => r !== "attendee")
                    .map((r) => (
                      <Badge
                        key={r}
                        className={
                          r === "super_admin" || r === "admin"
                            ? "bg-primary text-primary-foreground"
                            : "bg-accent-soft text-accent-foreground"
                        }
                      >
                        {ROLE_LABEL[r] ?? r}
                      </Badge>
                    ))}
                </div>
              </div>
            </Card>
          ))}
          {filtered.length === 0 && (
            <p className="py-6 text-center text-sm text-muted-foreground">No matches.</p>
          )}
        </div>
      )}
    </section>
  );
}
