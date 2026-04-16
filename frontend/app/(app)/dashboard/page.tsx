"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Loader2, Play, AlertCircle, RefreshCw,
  Activity, CheckCircle2, Database, TrendingUp,
  Server, Cpu, TestTube, Shield, Container, Radio,
  Zap,
} from "lucide-react";
import { useIncidents } from "@/lib/hooks/use-incidents";
import { IncidentCard } from "@/components/incident-card";
import { SkeletonCard } from "@/components/ui/skeleton";
import { Badge } from "@/components/ui/badge";
import { StatCard } from "@/components/ui/stat-card";
import { api } from "@/lib/api-client";
import { cn } from "@/lib/utils";

const SCENARIOS = [
  { id: "postgres_refused",   label: "Postgres Refused",   type: "infra",    icon: Server,    color: "text-amber-500" },
  { id: "oom_kill",           label: "OOM Kill",           type: "oom",      icon: Cpu,       color: "text-red-500"   },
  { id: "test_failure",       label: "Test Failure",       type: "test",     icon: TestTube,  color: "text-blue-500"  },
  { id: "secret_leak",        label: "Secret Leak",        type: "security", icon: Shield,    color: "text-rose-500"  },
  { id: "image_pull_backoff", label: "Image Pull Backoff", type: "deploy",   icon: Container, color: "text-sky-500"   },
];

export default function DashboardPage() {
  const { incidents, loading, error, refetch } = useIncidents(4000);
  const [simulating, setSimulating] = useState<string | null>(null);
  const router = useRouter();

  async function simulate(scenario: string) {
    setSimulating(scenario);
    try {
      const result = await api.simulate(scenario);
      refetch();
      router.push(`/incidents/${result.incident_id}`);
    } catch {
      // silently fail
    } finally {
      setSimulating(null);
    }
  }

  const activeCount   = incidents.filter(i => i.status === "processing" || i.status === "awaiting_approval").length;
  const resolvedCount = incidents.filter(i => i.status === "resolved").length;
  const failedCount   = incidents.filter(i => i.status === "failed").length;

  return (
    <div className="min-h-screen bg-background">
      {/* ── Header ─────────────────────────────────────────── */}
      <div className="border-b border-slate-200 bg-white sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-6 py-5 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-9 h-9 rounded-xl bg-orange-600 shadow-sm shadow-orange-500/10">
              <Activity className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-base font-black text-slate-900 tracking-tight uppercase">Dashboard</h1>
              <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-0.5">Real-time CI/CD Repair</p>
            </div>
          </div>
          <button
            onClick={refetch}
            className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-slate-500 hover:text-slate-900 hover:bg-slate-50 transition-all border border-slate-100 shadow-sm"
          >
            <RefreshCw className={cn("w-3.5 h-3.5", loading && "animate-spin")} />
            REFRESH
          </button>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-6 space-y-6">

        {/* ── Stats ──────────────────────────────────────────── */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            label="Total Incidents"
            value={incidents.length}
            icon={<Activity className="w-4 h-4" />}
            accent="hsl(215 25% 15%)"
          />
          <StatCard
            label="Active Now"
            value={activeCount}
            sub={activeCount > 0 ? "Processing..." : "All clear"}
            trend={activeCount > 0 ? "up" : "neutral"}
            icon={<Zap className="w-4 h-4" />}
            accent="hsl(28 100% 50%)"
          />
          <StatCard
            label="Resolved"
            value={resolvedCount}
            sub={incidents.length > 0 ? `${Math.round(resolvedCount / incidents.length * 100)}% success` : undefined}
            trend="up"
            icon={<CheckCircle2 className="w-4 h-4" />}
            accent="hsl(142 76% 36%)"
          />
          <StatCard
            label="Failed"
            value={failedCount}
            icon={<TrendingUp className="w-4 h-4" />}
            accent="hsl(0 84% 60%)"
          />
        </div>

        {/* ── Simulator ──────────────────────────────────────── */}
        <div className="rounded-xl border border-border bg-card overflow-hidden">
          <div className="flex items-center gap-3 px-5 py-3.5 border-b border-border bg-background-subtle/50">
            <Radio className="w-4 h-4 text-purple-500" />
            <div>
              <p className="text-sm font-semibold text-foreground">Failure Simulator</p>
              <p className="text-xs text-muted-foreground">Inject a real-looking CI/CD incident to demo the pipeline</p>
            </div>
            <span className="ml-auto chip bg-purple-500/10 text-purple-500 border border-purple-500/20">
              DEMO MODE
            </span>
          </div>

          <div className="p-5">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-2">
              {SCENARIOS.map((s) => {
                const busy = simulating === s.id;
                const Icon = s.icon;
                return (
                  <button
                    key={s.id}
                    onClick={() => simulate(s.id)}
                    disabled={!!simulating}
                    className={cn(
                      "group relative flex flex-col items-start gap-2.5 p-4 rounded-xl",
                      "border border-slate-100 bg-white hover:bg-slate-50",
                      "transition-all hover:border-orange-200 hover:shadow-lg hover:shadow-orange-500/5",
                      "disabled:opacity-50 disabled:cursor-not-allowed",
                      "text-left"
                    )}
                  >
                    <div className={cn("flex items-center justify-center w-9 h-9 rounded-xl bg-slate-50 border border-slate-100", busy && "animate-pulse")}>
                      {busy
                        ? <Loader2 className="w-4 h-4 animate-spin text-orange-500" />
                        : <Icon className={cn("w-4 h-4", s.color)} />
                      }
                    </div>
                    <div>
                      <p className="text-xs font-bold text-slate-900 leading-snug">{s.label}</p>
                      <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">{s.type}</p>
                    </div>
                    {!simulating && (
                      <div className="absolute top-4 right-4 w-6 h-6 rounded-full bg-slate-50 flex items-center justify-center border border-slate-100 opacity-0 group-hover:opacity-100 transition-all">
                        <Play className="w-2.5 h-2.5 text-orange-500 fill-orange-500" />
                      </div>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* ── Incidents ──────────────────────────────────────── */}
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-semibold text-foreground">
              Recent Incidents
              {incidents.length > 0 && (
                <span className="ml-2 text-xs font-normal text-muted-foreground">
                  {incidents.length} total
                </span>
              )}
            </h2>
            {loading && incidents.length > 0 && (
              <Loader2 className="w-3.5 h-3.5 animate-spin text-muted-foreground" />
            )}
          </div>

          {error && (
            <div className="flex items-center gap-3 p-4 rounded-xl border border-destructive/20 bg-destructive/5 text-sm text-destructive">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              <span>{error} — is the backend running?</span>
            </div>
          )}

          {loading && !incidents.length ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={i} />)}
            </div>
          ) : incidents.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 rounded-xl border border-dashed border-border text-center">
              <div className="w-12 h-12 rounded-2xl bg-muted flex items-center justify-center mb-4">
                <Radio className="w-5 h-5 text-muted-foreground" />
              </div>
              <p className="text-sm font-medium text-foreground">No incidents yet</p>
              <p className="text-xs text-muted-foreground mt-1">
                Use the simulator above to inject a failure scenario
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {incidents.map((inc, i) => (
                <div
                  key={inc.id}
                  className="fade-up"
                  style={{ animationDelay: `${i * 40}ms` }}
                >
                  <IncidentCard incident={inc} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
