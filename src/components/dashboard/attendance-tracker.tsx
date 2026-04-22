"use client";

import { useState, useEffect } from "react";
import { Play, Pause, Square, Loader2, Clock, FileText, Check } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { cn } from "@/lib/utils";
import { startAttendance, updateAttendanceStatus, getActiveAttendance } from "@/app/actions/attendance";

export function AttendanceTracker() {
  const [status, setStatus] = useState<"IDLE" | "WORKING" | "ON_BREAK">("IDLE");
  const [startTime, setStartTime] = useState<number | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const [loading, setLoading] = useState(true);
  const [report, setReport] = useState("");
  const [showReportInput, setShowReportInput] = useState(false);
  const [completedToday, setCompletedToday] = useState(false);

  // Sync with database on load
  useEffect(() => {
    async function sync() {
      try {
        const active = await getActiveAttendance();
        if (active) {
          setStatus(active.status as any);
          setStartTime(new Date(active.startTime).getTime());
        } else {
          // Check if already completed a session today
          const res = await fetch("/api/attendance/check-today");
          const { completed } = await res.json();
          setCompletedToday(completed);
        }
      } catch (error) {
        console.error("Failed to sync attendance:", error);
      } finally {
        setLoading(false);
      }
    }
    sync();
  }, []);

  // Update timer
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (status !== "IDLE" && startTime) {
      interval = setInterval(() => {
        setElapsed(Date.now() - startTime);
      }, 1000);
    } else {
      setElapsed(0);
    }
    return () => clearInterval(interval);
  }, [status, startTime]);

  const formatTime = (ms: number) => {
    const seconds = Math.floor((ms / 1000) % 60);
    const minutes = Math.floor((ms / (1000 * 60)) % 60);
    const hours = Math.floor(ms / (1000 * 60 * 60));
    return `${hours.toString().padStart(2, "0")}:${minutes
      .toString()
      .padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  };

  const handleAction = async (action: "CHECK_IN" | "BREAK" | "RESUME" | "CHECK_OUT") => {
    if (action === "CHECK_OUT" && status === "WORKING" && !showReportInput) {
      setShowReportInput(true);
      return;
    }

    setLoading(true);
    try {
      if (action === "CHECK_IN") {
        const res = await startAttendance();
        setStatus("WORKING");
        setStartTime(new Date(res.startTime).getTime());
      } else if (action === "BREAK") {
        await updateAttendanceStatus("BREAK");
        setStatus("ON_BREAK");
      } else if (action === "RESUME") {
        await updateAttendanceStatus("RESUME");
        setStatus("WORKING");
      } else if (action === "CHECK_OUT") {
        await updateAttendanceStatus("FINISH", report || undefined);
        setStatus("IDLE");
        setStartTime(null);
        setElapsed(0);
        setReport("");
        setShowReportInput(false);
        setCompletedToday(true);
      }
    } catch (error: any) {
      alert(error.message || "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  if (loading && status === "IDLE") {
    return (
      <div className="glass rounded-3xl p-8 flex items-center justify-center min-h-[300px]">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="glass rounded-3xl p-8 space-y-8">
      <div className="flex items-center justify-between">
        <h3 className="text-xl font-bold flex items-center gap-2">
          <Clock className="w-5 h-5 text-primary" />
          Attendance Tracker
        </h3>
        <div className={cn(
          "px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider",
          status === "WORKING" ? "bg-green-500/10 text-green-500" :
          status === "ON_BREAK" ? "bg-orange-500/10 text-orange-500" :
          "bg-slate-500/10 text-slate-500"
        )}>
          {status === "WORKING" ? "Clocked In" : status === "ON_BREAK" ? "On Break" : "Offline"}
        </div>
      </div>

      <AnimatePresence mode="wait">
        {!showReportInput ? (
          <motion.div 
            key="timer"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex flex-col items-center justify-center space-y-4 py-8"
          >
            <div className="text-6xl font-mono font-bold tracking-tighter tabular-nums text-white">
              {formatTime(elapsed)}
            </div>
            <p className="text-muted-foreground text-sm">
              {status === "IDLE" ? 
                (completedToday ? "Your work day is complete. See you tomorrow!" : "Ready to start your day?") : 
                status === "ON_BREAK" ? "Enjoy your break!" : "Keep up the great work!"
              }
            </p>
          </motion.div>
        ) : (
          <motion.div 
            key="report"
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="space-y-4 py-4"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-primary mb-2">
              <FileText className="w-4 h-4" />
              Daily Work Summary
            </div>
            <textarea
              value={report}
              onChange={(e) => setReport(e.target.value)}
              placeholder="What did you accomplish today? (Bullet points preferred)"
              className="w-full bg-slate-900/50 border border-border rounded-2xl py-4 px-4 focus:ring-2 focus:ring-primary outline-none transition-all resize-none text-white text-sm"
              rows={5}
            />
          </motion.div>
        )}
      </AnimatePresence>

      <div className="grid grid-cols-2 gap-4">
        {status === "IDLE" ? (
          <button
            onClick={() => handleAction("CHECK_IN")}
            disabled={loading || completedToday}
            className={cn(
              "col-span-2 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50",
              completedToday ? "bg-slate-800 text-slate-500 cursor-not-allowed" : "bg-primary hover:bg-primary-hover text-white shadow-lg shadow-primary/20"
            )}
          >
            {loading ? <Loader2 className="animate-spin w-5 h-5" /> : (completedToday ? <Check className="w-5 h-5" /> : <Play className="w-5 h-5 fill-current" />)}
            {completedToday ? "Day Finished" : "Start Working Day"}
          </button>
        ) : (
          <>
            {!showReportInput && (
              <>
                {status === "WORKING" ? (
                  <button
                    onClick={() => handleAction("BREAK")}
                    disabled={loading}
                    className="bg-orange-500/10 hover:bg-orange-500/20 text-orange-500 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50"
                  >
                    {loading ? <Loader2 className="animate-spin w-5 h-5" /> : <Pause className="w-5 h-5 fill-current" />}
                    Take Break
                  </button>
                ) : (
                  <button
                    onClick={() => handleAction("RESUME")}
                    disabled={loading}
                    className="bg-green-500/10 hover:bg-green-500/20 text-green-500 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50"
                  >
                    {loading ? <Loader2 className="animate-spin w-5 h-5" /> : <Play className="w-5 h-5 fill-current" />}
                    Resume Work
                  </button>
                )}
              </>
            )}
            
            <button
              onClick={() => showReportInput ? handleAction("CHECK_OUT") : setShowReportInput(true)}
              disabled={loading || (showReportInput && report.length < 10)}
              className={cn(
                "py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50",
                showReportInput ? "bg-primary text-white col-span-2 shadow-lg shadow-primary/20" : "bg-destructive/10 hover:bg-destructive/20 text-destructive"
              )}
            >
              {loading ? <Loader2 className="animate-spin w-5 h-5" /> : <Square className="w-5 h-5 fill-current" />}
              {showReportInput ? "Confirm Checkout" : "Finish Day"}
            </button>

            {showReportInput && (
              <button
                onClick={() => setShowReportInput(false)}
                className="col-span-2 text-sm text-muted-foreground hover:text-white transition-colors py-2"
              >
                Cancel
              </button>
            )}
          </>
        )}
      </div>
    </div>
  );
}
