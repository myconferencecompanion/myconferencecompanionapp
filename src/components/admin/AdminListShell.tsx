import { type ReactNode, useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Plus, Pencil, Trash2 } from "lucide-react";

export function AdminListShell<T extends { id: string }>({
  title,
  items,
  rowTitle,
  rowSubtitle,
  onDelete,
  renderForm,
  emptyText = "Nothing yet.",
}: {
  title: string;
  items: T[];
  rowTitle: (t: T) => ReactNode;
  rowSubtitle?: (t: T) => ReactNode;
  onDelete?: (t: T) => Promise<void> | void;
  renderForm: (close: () => void, editing: T | null) => ReactNode;
  emptyText?: string;
}) {
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<T | null>(null);

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="text-base font-semibold">{title}</h2>
        <Dialog
          open={open}
          onOpenChange={(v) => {
            setOpen(v);
            if (!v) setEditing(null);
          }}
        >
          <DialogTrigger asChild>
            <Button size="sm">
              <Plus className="h-4 w-4" /> Add
            </Button>
          </DialogTrigger>
          <DialogContent className="max-h-[90vh] overflow-y-auto">
            <DialogHeader>
              <DialogTitle>{editing ? "Edit" : "Add new"}</DialogTitle>
            </DialogHeader>
            {renderForm(() => setOpen(false), editing)}
          </DialogContent>
        </Dialog>
      </div>

      {items.length === 0 ? (
        <p className="py-12 text-center text-sm text-muted-foreground">{emptyText}</p>
      ) : (
        <div className="space-y-2">
          {items.map((it) => (
            <Card key={it.id} className="flex items-center gap-3 border-0 p-3 shadow-card">
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold">{rowTitle(it)}</p>
                {rowSubtitle && (
                  <p className="truncate text-xs text-muted-foreground">{rowSubtitle(it)}</p>
                )}
              </div>
              <Button
                size="icon"
                variant="ghost"
                className="h-8 w-8"
                onClick={() => {
                  setEditing(it);
                  setOpen(true);
                }}
              >
                <Pencil className="h-3.5 w-3.5" />
              </Button>
              {onDelete && (
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-8 w-8 text-destructive"
                  onClick={async () => {
                    if (confirm("Delete?")) await onDelete(it);
                  }}
                >
                  <Trash2 className="h-3.5 w-3.5" />
                </Button>
              )}
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
