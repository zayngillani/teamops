"use client";

import { useState } from "react";
import { approveLinkedInPost, rejectLinkedInPost } from "@/app/actions/linkedin";
import { CheckCircle2, XCircle, Clock, Send, CalendarIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export function AdminLinkedInClient({ pendingPosts, resolvedPosts }: { pendingPosts: any[]; resolvedPosts: any[] }) {
  const [activeTab, setActiveTab] = useState<"pending" | "resolved">("pending");
  const [rejectingId, setRejectingId] = useState<string | null>(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleApprove(id: string) {
    if (!confirm("Are you sure you want to approve this post?")) return;
    setIsSubmitting(true);
    try {
      await approveLinkedInPost(id);
    } catch (error) {
      console.error(error);
      alert("Failed to approve post");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleReject(id: string) {
    if (!rejectionReason.trim()) {
      alert("Please provide a reason for rejection.");
      return;
    }
    setIsSubmitting(true);
    try {
      await rejectLinkedInPost(id, rejectionReason);
      setRejectingId(null);
      setRejectionReason("");
    } catch (error) {
      console.error(error);
      alert("Failed to reject post");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4 border-b border-border">
        <button
          onClick={() => setActiveTab("pending")}
          className={cn(
            "pb-4 px-2 font-bold text-sm border-b-2 transition-all",
            activeTab === "pending" ? "border-primary text-primary" : "border-transparent text-muted-foreground hover:text-white"
          )}
        >
          Pending Review ({pendingPosts.length})
        </button>
        <button
          onClick={() => setActiveTab("resolved")}
          className={cn(
            "pb-4 px-2 font-bold text-sm border-b-2 transition-all",
            activeTab === "resolved" ? "border-primary text-primary" : "border-transparent text-muted-foreground hover:text-white"
          )}
        >
          Resolved ({resolvedPosts.length})
        </button>
      </div>

      {activeTab === "pending" && (
        <div className="space-y-6">
          {pendingPosts.length === 0 ? (
            <div className="glass p-12 text-center rounded-3xl border border-dashed border-border">
              <CheckCircle2 className="w-12 h-12 text-green-500/50 mx-auto mb-4" />
              <p className="text-muted-foreground">All caught up! No posts pending approval.</p>
            </div>
          ) : (
            pendingPosts.map((post) => (
              <div key={post.id} className="glass p-6 rounded-3xl space-y-6 border border-primary/20">
                <div className="flex justify-between items-start">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold">
                      {post.user?.name?.[0] || "U"}
                    </div>
                    <div>
                      <p className="font-bold text-white">{post.user?.name}</p>
                      <p className="text-xs text-muted-foreground">
                        Submitted {new Date(post.createdAt).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  {post.scheduledAt && (
                    <div className="flex items-center gap-2 text-xs font-bold bg-blue-500/10 text-blue-500 px-3 py-1.5 rounded-full">
                      <CalendarIcon className="w-3.5 h-3.5" />
                      Scheduled for {new Date(post.scheduledAt).toLocaleDateString()}
                    </div>
                  )}
                </div>

                <div className="bg-slate-900/50 p-4 rounded-2xl text-sm text-slate-300 leading-relaxed whitespace-pre-wrap">
                  {post.content}
                </div>

                {rejectingId === post.id ? (
                  <div className="space-y-3 pt-4 border-t border-border">
                    <p className="text-sm font-bold text-orange-500">Provide rejection reason:</p>
                    <textarea
                      value={rejectionReason}
                      onChange={(e) => setRejectionReason(e.target.value)}
                      className="w-full bg-slate-900 text-white border border-border rounded-xl p-3 text-sm min-h-[80px]"
                      placeholder="e.g. Needs more professional tone..."
                    />
                    <div className="flex justify-end gap-3">
                      <button
                        onClick={() => setRejectingId(null)}
                        className="px-4 py-2 text-sm font-medium hover:text-white"
                        disabled={isSubmitting}
                      >
                        Cancel
                      </button>
                      <button
                        onClick={() => handleReject(post.id)}
                        disabled={isSubmitting}
                        className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2"
                      >
                        {isSubmitting ? "Rejecting..." : "Confirm Reject"}
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="flex gap-4 pt-4 border-t border-border">
                    <button
                      onClick={() => handleApprove(post.id)}
                      disabled={isSubmitting}
                      className="flex-1 bg-green-500 hover:bg-green-600 text-white py-3 rounded-xl font-bold flex items-center justify-center gap-2 transition-all"
                    >
                      <CheckCircle2 className="w-5 h-5" />
                      Approve Post
                    </button>
                    <button
                      onClick={() => setRejectingId(post.id)}
                      disabled={isSubmitting}
                      className="flex-1 bg-slate-800 hover:bg-slate-700 text-white py-3 rounded-xl font-bold flex items-center justify-center gap-2 transition-all border border-border"
                    >
                      <XCircle className="w-5 h-5 text-orange-500" />
                      Reject
                    </button>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      )}

      {activeTab === "resolved" && (
        <div className="space-y-4">
          {resolvedPosts.map((post) => (
            <div key={post.id} className="glass p-5 rounded-2xl flex items-center justify-between border-l-4" style={{
              borderLeftColor: post.status === "approved" || post.status === "published" || post.status === "scheduled" ? "#22c55e" : "#f97316"
            }}>
              <div>
                <p className="font-bold text-sm">{post.user?.name}</p>
                <p className="text-xs text-muted-foreground truncate max-w-md">{post.content}</p>
              </div>
              <div className="text-right">
                <span className={cn(
                  "text-[10px] font-bold px-2 py-1 rounded-md uppercase tracking-wider",
                  (post.status === "approved" || post.status === "published" || post.status === "scheduled") ? "bg-green-500/10 text-green-500" : "bg-orange-500/10 text-orange-500"
                )}>
                  {post.status}
                </span>
                <p className="text-[10px] text-muted-foreground mt-1">
                  {new Date(post.updatedAt).toLocaleDateString()}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
