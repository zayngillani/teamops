"use client";

import { useEffect, useState } from "react";
import { getMonthlySummary } from "@/app/actions/attendance";
import { Clock, Coffee, TrendingUp } from "lucide-react";

export function MonthlySummary({ userId }: { userId?: string }) {
  const [summary, setSummary] = useState<{ totalWorkMs: number; totalBreakMs: number; logCount: number } | null>(null);

  useEffect(() => {
    async function load() {
      const data = await getMonthlySummary(userId);
      setSummary(data);
    }
    load();
  }, [userId]);

  if (!summary) return null;

  const formatValue = (ms: number) => {
    const absMs = Math.max(0, ms);
    const h = Math.floor(absMs / 3600000);
    const m = Math.floor((absMs % 3600000) / 60000);
    return `${h}h ${m}m`;
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div className="glass rounded-3xl p-6 space-y-2 border-green-500/10">
        <div className="flex items-center gap-2 text-green-500 text-sm font-bold">
          <Clock className="w-4 h-4" />
          WORK HOURS
        </div>
        <div className="text-3xl font-bold font-display">{formatValue(summary.totalWorkMs)}</div>
        <p className="text-xs text-muted-foreground uppercase tracking-widest">This Month</p>
      </div>

      <div className="glass rounded-3xl p-6 space-y-2 border-orange-500/10">
        <div className="flex items-center gap-2 text-orange-500 text-sm font-bold">
          <Coffee className="w-4 h-4" />
          BREAK TIME
        </div>
        <div className="text-3xl font-bold font-display">{formatValue(summary.totalBreakMs)}</div>
        <p className="text-xs text-muted-foreground uppercase tracking-widest">This Month</p>
      </div>

      <div className="glass rounded-3xl p-6 space-y-2 border-primary/10">
        <div className="flex items-center gap-2 text-primary text-sm font-bold">
          <TrendingUp className="w-4 h-4" />
          DAYS LOGGED
        </div>
        <div className="text-3xl font-bold font-display">{summary.logCount}</div>
        <p className="text-xs text-muted-foreground uppercase tracking-widest">Attendance Streak</p>
      </div>
    </div>
  );
}
