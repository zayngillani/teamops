"use client";

import { useState } from "react";
import { Check, X, Loader2 } from "lucide-react";
import { updateLeaveStatus } from "@/app/actions/leaves";

export function LeaveStatusButtons({ leaveId }: { leaveId: string }) {
  const [loading, setLoading] = useState<"APPROVE" | "REJECT" | null>(null);

  const handleUpdate = async (status: "APPROVED" | "REJECTED") => {
    setLoading(status === "APPROVED" ? "APPROVE" : "REJECT");
    try {
      await updateLeaveStatus(leaveId, status);
    } catch (error: any) {
      alert(error.message || "Failed to update leave status");
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="flex items-center gap-2">
      <button
        onClick={() => handleUpdate("APPROVED")}
        disabled={loading !== null}
        className="flex items-center gap-1 text-green-500 bg-green-500/10 hover:bg-green-500/20 px-3 py-1 rounded-full text-xs font-bold transition-all disabled:opacity-50"
      >
        {loading === "APPROVE" ? <Loader2 className="w-3 h-3 animate-spin" /> : <Check className="w-3 h-3" />}
        Approve
      </button>
      <button
        onClick={() => handleUpdate("REJECTED")}
        disabled={loading !== null}
        className="flex items-center gap-1 text-destructive bg-destructive/10 hover:bg-destructive/20 px-3 py-1 rounded-full text-xs font-bold transition-all disabled:opacity-50"
      >
        {loading === "REJECT" ? <Loader2 className="w-3 h-3 animate-spin" /> : <X className="w-3 h-3" />}
        Reject
      </button>
    </div>
  );
}
