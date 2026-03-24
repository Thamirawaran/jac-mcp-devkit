# 🚀 jac-mcp-devkit

I’m a compiler and computer architecture person. I don’t enjoy vibe coding, but agentic development is a different thing — it’s actually efficient and fun. That’s what this repo is about.

Here I’m improving **[Jac MCP](https://github.com/jaseci-labs/jaseci/tree/main/jac-mcp)**, pushing it to **maximum efficiency**, and using it to build **full-fledged applications in Jac on the [Jaseci stack](https://github.com/jaseci-labs/jaseci), with minimal effort**.

Not just for fun, but to explore:

> “What is the right way to build software using agents?”

---

## 💡 Why Jac & the [Jaseci stack](https://github.com/jaseci-labs/jaseci)?

Jac is an **abstracted full-stack language**, where a lot of the usual complexity is already gone by design.

My bet is simple:

> Let the language handle the stack complexity. Let AI handle the rest. 😄

That's the combo I'm testing here.

---

## 🧪 My approach to building apps (important ⚠️)

I follow a structured “shot-based” approach when building apps:

### 🔹 Small apps
- 1-shot prompt
  - a few fix prompts

### 🔹 Mid-range apps
- 1-5 shot prompts
  - 1 sample architecture idea
  - a few fix prompts

### 🔹 Large apps
- 5-10 shot prompts
  - 1 full architecture idea
  - a few fix prompts

---

## 🚧 Failure rules (very important)

I strictly follow this rule:

> If it fails after **5 continuous fix prompts**, I consider it a failure.

- I will **stop working on it**
- Upload whatever I built up to that point to GitHub
- Take it as a signal that **[Jac MCP](https://github.com/jaseci-labs/jaseci/tree/main/jac-mcp) needs improvement** and come back to it later 😄

Otherwise:
- I upload the **fully working app**

---

## 📦 Apps

| App | Size | Design Guide | Prompts | Fix Prompts | Dev Notes | Review | Success |
|-----|------|-------------|---------|-------------|-----------|--------|---------|
| [TaskFlow](taskflow/) | Small | 0 | 1 | 0 | [Dev Notes](taskflow/DEV_NOTES.md) | [Review](taskflow/REVIEW.md) | ✅ |
| [Project Manager](project_manager/) | Small | 0 | 1 | 3 | [Dev Notes](project_manager/DEV_NOTES.md) | [Review](project_manager/REVIEW.md) | ✅ |

> Dev Notes — AI did the hard work, so it gets to write about its own problems 🤖
>
> Review — I take the credit, so I get to write about how great it is 😄


---

## 🔄 Current state

This is an ongoing journey.

Some things will work  
some things will break  
some ideas will fail 😅  

That’s part of the process.

---

## ⭐ If you’re here

You probably care about:
- agents  
- building things properly  

Welcome 🙂