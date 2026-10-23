## AI tip: give it the whole picture, and keep the guardrails

Healthy pods say nothing about the path between them. An AI that sees one resource can only guess about the rest.

🚫 **Bad:** paste one YAML file and ask "why can't they talk?" (then accept "just delete the policy").

✅ **Good:** paste **every** resource kind in the namespace that touches traffic, plus the pod labels, and ask:
"Which fields disagree with each other? Quote both sides. Give the MINIMAL change that keeps the
security intent. How do I verify each fix separately?"

**Check before you trust it:**
- Reject fixes that remove protection (deleting policies, `hostNetwork`, privileged mode).
- Fix one thing, re-run the failing request and paste the new result back. A changed symptom is evidence.
- Treat the answer as a hypothesis. Confirm it in the cluster.
