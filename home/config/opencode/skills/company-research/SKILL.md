---
name: company-research
description: Research a company and produce a concise, sourced Markdown brief and an outreach message draft. Use when the user wants company research covering its business model, products, customers, news, jobs, and potential technology leaders, saved in a company-named folder.
---

# Company Research

Research one company and write a concise, sourced Markdown brief. Keep process and shape stable, but make every fact company-specific and current.

## Output rules

- Answer in the user’s language.
- Create one folder named after the company, with spaces replaced by `-` (example: `Acme-Corp/`). Use a safe directory name without path separators or traversal components.
- Inside that folder, create a brief named `<company-name>.md` in lowercase with dashes (example: `acme-corp.md`) and an outreach draft named `message.md`. Do not overwrite existing files without user approval.
- Separate each requested point by paragraph/section. Be concise and precise.
- Include the research date and source URLs for material claims in the brief, either alongside claims or as clearly mapped references at the end.
- Never present unverified people or contact data as certain. Mark information supported only by non-official sources as needing validation before outreach.

## Research workflow

1. Identify exact legal/brand name, ticker if public, HQ, founding year, and official site.
2. Search official sources first:
   - About/overview page
   - Product/pricing pages
   - Investor relations: overview, why invest, executive management, board, financial reports, SEC/SEDAR filings
   - Newsroom and recent press releases
   - Careers/openings page
3. Add relevant secondary sources when useful, including reputable business press and LinkedIn for people. Treat press releases as company statements, not independent verification.
4. Check the official website and available public LinkedIn profiles for team members and roles. Check current job openings and their locations where available.

Use parallel searches where possible.

## Facts to extract

- **Business model**: what the company sells, revenue streams, pricing/monetization, key growth levers.
- **Products/how sold**: main product lines, modules, services, hardware/financial services if relevant, delivery channels.
- **Target customers**: industries, company size, geographies, customer count/locations/GTV/GMV if published, explicit exclusions.
- **Latest news**: product launches, leadership changes, financial results, partnerships, board changes, major warnings/layoffs or any other news that could serve as a conversation starter. Prefer last 6–12 months and include dates.
- **Jobs**: report available evidence of openings, especially infrastructure, SRE, DevOps, and Linux administration roles. If the careers page is inaccessible or inconclusive, say openings could not be verified rather than claiming none exist.
- **Contacts**: prioritize CTO, VP Engineering, Head of Engineering, and technical founder. If not found, use the closest confirmed senior technology/product leader or founder/CEO. Prefer official sources and public LinkedIn profiles; mark third-party-only information as needing validation. Include public contact channels when available, without guessing private contact details.
- If a fact cannot be verified, say so or omit it rather than inventing it. Disambiguate similarly named companies before researching; ask the user if the intended company remains unclear.

## Markdown template

Use this structure unless the user requests another. Translate headings and labels into the user's language; omit unsupported examples and add the research date.

```md
# <Company> — recherche concise

<Concise paragraph: what company is, what it sells, revenue streams, sales/monetization logic. Sources: <urls>>

<Concise paragraph: product lines/modules/services and go-to-market motion. Sources: <urls>>

## Clients cible

<Concise paragraph: target industries, sizes, geographies, scale metrics, exclusions. Sources: <urls>>

## Dernières actualités

<YYYY-MM-DD>: <news item>. Source: <url>

<YYYY-MM-DD>: <news item>. Source: <url>

## Offres d’emploi

<Oui/non/indéterminé + relevant openings and locations. Source officielle: <url>>

## Contacts possibles

Contact le plus solide: <Name>, <role> — <why relevant>; confirmation source: <official url>

Autre contact senior: <Name>, <role> — <why relevant>; source: <official url>

Piste moins certaine: <Name>, <role> — source non officielle; à valider avant outreach. Sources: <urls>

Canaux publics: <contact page / investor contact / LinkedIn company page>. Sources: <urls>
```

## Validation before finishing

- Folder exists and uses `-` instead of spaces.
- Both Markdown files exist inside the folder and have been read back.
- Recent news dates are not older than requested scope unless context requires.
- Contacts section distinguishes official vs third-party confidence.
- If goal tracking is active, call goal completion only after file write and read-back verification.

## Outreach message draft

Write at least 3 distinct first-contact message options in `message.md`, addressed to the most relevant verified contact when possible. Use a curious and honest tone. Keep each option direct and as short as possible. Do not send any message.

Start the file with the contact's name and role on one line, followed by their verified public LinkedIn profile URL on the next line. If the name, role, or LinkedIn profile cannot be verified, use a clearly marked placeholder for the missing information; never guess.

Each message option must contain:
- A specific, sourced company fact from the brief.
- A concise introduction using only information the user provided, or a clearly marked placeholder.
- One open technical question relevant to the contact, the company fact, and monitoring or infrastructure where appropriate.

Arrange these elements in whichever order reads most naturally for the specific message. Label the options clearly so they are easy to compare.

Use this structure:

```md
<Name>: <role>
<Verified LinkedIn profile URL or placeholder>

## Message 1

<Short message>

## Message 2

<Short message>

## Message 3

<Short message>
```

## News

Select a specific, relevant fact or news item from the brief. Connect it to the user's expertise or offer only when that context is known.

## Presentation

Briefly introduce the user using only information they provided. If their background or offer is unknown, use a clearly marked placeholder rather than inventing credentials.

## Open question

Ask an open question about the company, relating it to monitoring/infrastructure, the selected fact and contact's role where appropriate.
