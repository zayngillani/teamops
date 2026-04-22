"use client";

import { useState } from "react";
import { createLinkedInPost, updateLinkedInPost, submitPostForApproval } from "@/app/actions/linkedin";
import { Send, Clock, Plus, X } from "lucide-react";
import { cn } from "@/lib/utils";

export function LinkedInCreatorClient({ post }: { post?: any }) {
  const [isOpen, setIsOpen] = useState(false);
  const [content, setContent] = useState(post?.content || "");
  const [scheduledAt, setScheduledAt] = useState(post?.scheduledAt ? new Date(post.scheduledAt).toISOString().slice(0, 16) : "");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isEditing = !!post;

  async function handleSaveDraft() {
    if (!content.trim()) return;
    setIsSubmitting(true);
    try {
      const data = { content, scheduledAt: scheduledAt ? new Date(scheduledAt) : undefined };
      if (isEditing) {
        await updateLinkedInPost(post.id, data);
        setIsOpen(false);
      } else {
        await createLinkedInPost(data);
        setContent("");
        setScheduledAt("");
        setIsOpen(false);
      }
    } catch (error) {
      console.error(error);
      alert("Failed to save draft");
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleSubmitApproval() {
    if (!isEditing) return; // Can only submit existing drafts
    setIsSubmitting(true);
    try {
      // First save any changes
      await updateLinkedInPost(post.id, { content, scheduledAt: scheduledAt ? new Date(scheduledAt) : undefined });
      // Then submit for approval
      await submitPostForApproval(post.id);
      setIsOpen(false);
    } catch (error) {
      console.error(error);
      alert("Failed to submit for approval");
    } finally {
      setIsSubmitting(false);
    }
  }

  if (!isOpen) {
    if (isEditing) {
      return (
        <button
          onClick={() => setIsOpen(true)}
          className="text-xs font-bold bg-white/10 hover:bg-white/20 px-4 py-2 rounded-lg transition-all"
        >
          Edit / Submit
        </button>
      );
    }
    return (
      <button
        onClick={() => setIsOpen(true)}
        className="w-full bg-[#0077B5] hover:bg-[#005a8a] text-white px-6 py-4 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 shadow-lg shadow-[#0077B5]/20"
      >
        <Plus className="w-5 h-5" />
        Draft New Post
      </button>
    );
  }

  return (
    <div className={cn("bg-slate-900/80 p-5 rounded-2xl border border-[#0077B5]/30 space-y-4", !isEditing && "fixed inset-0 z-50 m-auto w-[90%] max-w-2xl h-fit shadow-2xl backdrop-blur-sm")}>
      <div className="flex justify-between items-center">
        <h3 className="font-bold text-lg flex items-center gap-2">
          <Send className="w-5 h-5 text-[#0077B5]" />
          {isEditing ? "Edit Draft" : "Create LinkedIn Post"}
        </h3>
        <button onClick={() => setIsOpen(false)} className="p-2 hover:bg-white/10 rounded-full transition-colors">
          <X className="w-5 h-5" />
        </button>
      </div>

      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="What do you want to share with your professional network?"
        className="w-full h-40 bg-black/50 border border-white/10 rounded-xl p-4 outline-none focus:border-[#0077B5]/50 transition-colors resize-none text-sm leading-relaxed"
      />

      <div className="flex items-center gap-3">
        <Clock className="w-4 h-4 text-muted-foreground" />
        <input
          type="datetime-local"
          value={scheduledAt}
          onChange={(e) => setScheduledAt(e.target.value)}
          className="bg-black/50 border border-white/10 rounded-lg px-3 py-2 text-sm outline-none text-muted-foreground focus:text-white transition-colors"
        />
        <span className="text-xs text-muted-foreground">(Optional schedule)</span>
      </div>

      <div className="flex gap-3 pt-4">
        <button
          onClick={handleSaveDraft}
          disabled={isSubmitting || !content.trim()}
          className="flex-1 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 text-white py-3 rounded-xl font-bold transition-all text-sm"
        >
          {isSubmitting ? "Saving..." : "Save Draft"}
        </button>
        {isEditing && (
          <button
            onClick={handleSubmitApproval}
            disabled={isSubmitting || !content.trim()}
            className="flex-1 bg-[#0077B5] hover:bg-[#005a8a] disabled:opacity-50 text-white py-3 rounded-xl font-bold transition-all text-sm flex justify-center items-center gap-2 shadow-lg shadow-[#0077B5]/20"
          >
            <Send className="w-4 h-4" />
            Submit for Approval
          </button>
        )}
      </div>
    </div>
  );
}
