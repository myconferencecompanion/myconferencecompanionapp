// Demo-mode Supabase stub.
// When SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY are not configured (e.g. a
// deploy before the backend is connected), we hand out a harmless stub client
// instead of throwing at import time. Every query resolves to empty data,
// auth resolves to "signed out", and everything bundled (hotels, POIs,
// transport, FAQs, map) keeps working.
export const DEMO_MESSAGE =
  "Demo mode — live features (sign-in, orders, chats, announcements) unlock once the conference backend is connected.";

let warned = false;

function warnOnce() {
  if (warned || typeof console === "undefined") return;
  warned = true;
  console.info(`[Supabase] Not configured — running in demo mode. ${DEMO_MESSAGE}`);
}

type Row = Record<string, unknown>;

class StubQuery implements PromiseLike<{ data: null; error: { message: string } }> {
  then<T1, T2>(
    onfulfilled?: ((value: { data: null; error: { message: string } }) => T1 | PromiseLike<T1>) | null,
    onrejected?: ((reason: unknown) => T2 | PromiseLike<T2>) | null,
  ) {
    warnOnce();
    return Promise.resolve({ data: null, error: { message: "Supabase not configured (demo mode)" } }).then(
      onfulfilled,
      onrejected,
    );
  }
  catch<T2>(onrejected?: ((reason: unknown) => T2 | PromiseLike<T2>) | null) {
    return Promise.resolve({ data: null, error: { message: "Supabase not configured (demo mode)" } }).then(
      (v) => v,
      onrejected,
    );
  }
  finally(onfinally?: (() => void) | null) {
    return Promise.resolve({ data: null, error: null }).then(onfinally ?? (() => {}));
  }
  eq(): StubQuery {
    return this;
  }
  neq(): StubQuery {
    return this;
  }
  gte(): StubQuery {
    return this;
  }
  lte(): StubQuery {
    return this;
  }
  like(): StubQuery {
    return this;
  }
  ilike(): StubQuery {
    return this;
  }
  in(): StubQuery {
    return this;
  }
  contains(): StubQuery {
    return this;
  }
  order(): StubQuery {
    return this;
  }
  limit(): StubQuery {
    return this;
  }
  range(): StubQuery {
    return this;
  }
  single(): StubQuery {
    return this;
  }
  maybeSingle(): StubQuery {
    return this;
  }
  select(): StubQuery {
    return this;
  }
}

function stubQuery(): StubQuery {
  return new StubQuery();
}

function stubChannel() {
  return {
    on: () => stubChannel(),
    subscribe: () => ({ unsubscribe: () => {} }),
  };
}

function stubAuth() {
  return {
    async getUser() {
      warnOnce();
      return { data: { user: null }, error: null };
    },
    async getSession() {
      warnOnce();
      return { data: { session: null }, error: null };
    },
    onAuthStateChange() {
      warnOnce();
      return {
        data: {
          subscription: {
            unsubscribe() {
              /* no-op */
            },
          },
        },
      };
    },
    async signInWithPassword() {
      warnOnce();
      return { data: { user: null, session: null }, error: { message: DEMO_MESSAGE } };
    },
    async signUp() {
      warnOnce();
      return { data: { user: null, session: null }, error: { message: DEMO_MESSAGE } };
    },
    async signOut() {
      /* no-op */
    },
  };
}

/** Creates a catch-all stub shaped enough like a Supabase client for this app. */
export function createStubSupabaseClient() {
  const client: Record<string, unknown> = {
    auth: stubAuth(),
    rpc: () => stubQuery(),
    channel: () => stubChannel(),
    removeChannel: () => {},
    from: (_table: string) => stubQuery(),
    storage: { from: () => ({ getPublicUrl: () => ({ data: { publicUrl: "" } }) }) },
  };
  return new Proxy(client, {
    get(target, prop, receiver) {
      if (prop in target) return Reflect.get(target, prop, receiver);
      // Unknown method/property access: return a chainable no-op function
      return stubQuery;
    },
  });
}

export function isSupabaseConfigured(): boolean {
  if (typeof window !== "undefined") {
    const env = (import.meta as unknown as { env?: Record<string, string> }).env ?? {};
    return Boolean(env.VITE_SUPABASE_URL || env.SUPABASE_URL);
  }
  return Boolean(process.env.SUPABASE_URL);
}
