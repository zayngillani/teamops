"use client";

import { useState } from "react";
import { Calendar, Send, Loader2, CheckCircle, Info } from "lucide-react";
import { submitLeaveRequest } from "@/app/actions/leaves";

export function LeaveRequestForm() {
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [formData, setFormData] = useState({
    startDate: "",
    endDate: "",
    leaveType: "ANNUAL",
    reason: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await submitLeaveRequest(formData);
      setSubmitted(true);
      setFormData({ startDate: "", endDate: "", leaveType: "ANNUAL", reason: "" });
      setTimeout(() => setSubmitted(false), 3000);
    } catch (error: any) {
      alert(error.message || "Failed to submit request");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="glass rounded-3xl p-8 space-y-6">
      <h3 className="text-xl font-bold flex items-center gap-2">
        <Calendar className="w-5 h-5 text-primary" />
        New Leave Request
      </h3>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <label className="text-sm font-medium text-muted-foreground">Start Date</label>
            <input 
              type="date" 
              required
              value={formData.startDate}
              onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
              className="w-full bg-slate-900/50 border border-border rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-primary transition-all [color-scheme:dark]"
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium text-muted-foreground">End Date</label>
            <input 
              type="date" 
              required
              value={formData.endDate}
              onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
              className="w-full bg-slate-900/50 border border-border rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-primary transition-all [color-scheme:dark]"
            />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium text-muted-foreground">Leave Type</label>
          <select
            required
            value={formData.leaveType}
            onChange={(e) => setFormData({ ...formData, leaveType: e.target.value })}
            className="w-full bg-slate-900/50 border border-border rounded-xl py-3 px-4 outline-none focus:ring-2 focus:ring-primary transition-all [color-scheme:dark] appearance-none"
          >
            <option value="ANNUAL">Annual Leave</option>
            <option value="SICK">Sick Leave</option>
            <option value="CASUAL">Casual Leave</option>
            <option value="UNPAID">Unpaid Leave</option>
          </select>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium text-muted-foreground">Reason for Leave</label>
          <textarea
            required
            rows={4}
            value={formData.reason}
            onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
            className="w-full bg-slate-900/50 border border-border rounded-2xl py-4 px-4 focus:ring-2 focus:ring-primary outline-none transition-all resize-none"
            placeholder="Please provide a brief reason..."
          />
        </div>

        <div className="bg-primary/5 border border-primary/20 rounded-2xl p-4 flex gap-4 items-start">
          <Info className="w-5 h-5 text-primary shrink-0 mt-0.5" />
          <p className="text-xs text-muted-foreground leading-relaxed">
            Your request will be sent to the Admin via Slack for approval. You will be notified once a decision is made.
          </p>
        </div>

        <button
          type="submit"
          disabled={loading || submitted}
          className="w-full bg-primary hover:bg-primary-hover text-white py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 disabled:opacity-50"
        >
          {loading ? (
            <Loader2 className="w-5 h-5 animate-spin" />
          ) : submitted ? (
            <CheckCircle className="w-5 h-5" />
          ) : (
            <Send className="w-5 h-5" />
          )}
          {submitted ? "Request Sent!" : "Submit Request"}
        </button>
      </form>
    </div>
  );
}
