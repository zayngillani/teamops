"use client";

import { useState } from "react";
import { Send, FileText, Loader2, CheckCircle } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export function DailyReportForm() {
  const [report, setReport] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    
    // Simulation
    await new Promise((r) => setTimeout(r, 1500));
    
    setSubmitted(true);
    setLoading(false);
    setReport("");
    
    setTimeout(() => setSubmitted(false), 3000);
  };

  return (
    <div className="glass rounded-3xl p-8 space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-xl font-bold flex items-center gap-2">
          <FileText className="w-5 h-5 text-primary" />
          Submit Daily Report
        </h3>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <label className="text-sm font-medium text-muted-foreground">
            What did you accomplish today?
          </label>
          <textarea
            required
            value={report}
            onChange={(e) => setReport(e.target.value)}
            className="w-full bg-slate-900/50 border border-border rounded-2xl py-4 px-4 min-h-[200px] focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all resize-none"
            placeholder="• Worked on user authentication
• Integrated Prisma ORM
• Designed dashboard UI"
          />
        </div>

        <div className="flex items-center justify-between">
          <p className="text-xs text-muted-foreground">
            Your report will be sent to <span className="text-primary font-bold">#daily-reports</span> in Slack.
          </p>
          <button
            type="submit"
            disabled={loading || submitted || !report}
            className="bg-primary hover:bg-primary-hover text-white px-8 py-3 rounded-xl font-bold flex items-center gap-2 transition-all active:scale-95 disabled:opacity-50"
          >
            {loading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : submitted ? (
              <CheckCircle className="w-5 h-5" />
            ) : (
              <Send className="w-5 h-5" />
            )}
            {submitted ? "Sent!" : "Submit Report"}
          </button>
        </div>
      </form>
    </div>
  );
}
