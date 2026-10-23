## AI tip: ask for every cause, then re-check

The first error you see may not be the only one. An AI that sees one clue will often stop at one answer.

🚫 **Bad:** paste only the logs and ask "how do I fix it?"

✅ **Good:** paste the logs **and** the pod description **and** the configuration it reads, then ask:
"List EVERY distinct root cause, with the evidence line for each. What evidence would you still want?"

**Check before you trust it:**
- Change **one** thing at a time, then paste the *new* output back and ask "what now?".
- Ask for the smallest change the evidence justifies. Reject numbers with no evidence behind them.
- Treat the answer as a hypothesis. Confirm it in the cluster.
