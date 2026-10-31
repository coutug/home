---
name: company-research
description: Research any company and produce a concise sourced Markdown brief. Use when the user asks to investigate a company’s business model, what it sells and how, target customers, latest news, job openings, and reachable leaders such as CTO, VP Engineering, Head of Engineering, or technical founder, then wants a company-named folder with an MD file.
---

# Company Research

Research one company and write a concise, sourced Markdown brief. Keep process and shape stable, but make every fact company-specific and current.

## Output rules

- Answer in the user’s language.
- Create one folder named after the company, with spaces replaced by `-` (example: `Acme-Corp/`).
- Inside that folder, create one Markdown file, preferably `<company-name>.md` lowercase with dashes (example: `acme-corp.md`).
- Separate each requested point by paragraph/section. Be concise.
- Include collection date and sources for each material claim.
- Mark confidence clearly:
  - **Confirmed**: official company site, investor relations, SEC/SEDAR filings, official newsroom, official careers page.
  - **To validate**: LinkedIn, RocketReach, Crunchbase, third-party job boards, interviews, older articles.
- Never present unverified people/contact data as certain. If only non-official sources exist, say “à valider avant outreach”.

## Research workflow

1. Identify exact legal/brand name, ticker if public, HQ, founding year, and official site.
2. Search official sources first:
   - About/overview page
   - Product/pricing pages
   - Investor relations: overview, why invest, executive management, board, financial reports, SEC/SEDAR filings
   - Newsroom and recent press releases
   - Careers/openings page
3. Add high-quality secondary sources only when official sources are missing: reputable business press, PR Newswire/GlobeNewswire, SEC filings mirrors, LinkedIn for people.
4. Cross-check numbers. Prefer the latest fiscal/quarterly figure and label fiscal period precisely.
5. Capture URLs immediately next to claims while drafting.

## Searches to run

Use parallel searches where possible:

- `<Company> official about business model customers`
- `<Company> investor relations revenue subscription transaction-based annual report`
- `<Company> latest news official newsroom <current year>`
- `<Company> careers openings engineering product`
- `<Company> CTO VP Engineering Head of Engineering technical founder`
- `site:<company-domain> news <Company> CTO`
- `site:<company-domain> careers <Company> engineering manager director`

## Facts to extract

- **Business model**: what the company sells, revenue streams, pricing/monetization, sales motion (self-serve, trial, demo/quote, direct sales, partners), key growth levers.
- **Products/how sold**: main product lines, modules, services, hardware/financial services if relevant, delivery channels.
- **Target customers**: industries, company size, geographies, customer count/locations/GTV/GMV if published, explicit exclusions.
- **Latest news**: product launches, leadership changes, financial results, partnerships, board changes, major warnings/layoffs. Prefer last 6–12 months and include dates.
- **Jobs**: confirm whether openings exist; list 5–10 relevant examples, especially engineering/product/leadership roles, with location.
- **Contacts**: prioritize CTO, VP Engineering, Head of Engineering, technical founder. If not found, use closest confirmed senior technology/product leader and founder/CEO. Keep unofficial people clearly marked as “to validate”.

## Markdown template

Use this structure unless user requests another:

```md
# <Company> — recherche concise

Date de collecte: <YYYY-MM-DD>. Sources prioritaires: site officiel, relations investisseurs, filings, communiqués, page carrières.

## Business model

<Concise paragraph: what company is, what it sells, revenue streams, sales/monetization logic. Sources: <urls>

## Ce qu’elle vend et comment

<Concise paragraph: product lines/modules/services and go-to-market motion. Sources: <urls>

## Clients cible

<Concise paragraph: target industries, sizes, geographies, scale metrics, exclusions. Sources: <urls>

## Dernières actualités

<YYYY-MM-DD>: <news item>. Source: <url>

<YYYY-MM-DD>: <news item>. Source: <url>

<YYYY-MM-DD>: <news item>. Source: <url>

## Offres d’emploi

<Oui/non + relevant openings and locations. Source officielle: <url>

## Contacts possibles

Contact le plus solide: <Name>, <role> — <why relevant>; confirmation source: <official url>

Autre contact senior: <Name>, <role> — <why relevant>; source: <official url>

Piste moins certaine: <Name>, <role> — source non officielle; à valider avant outreach. Sources: <urls>

Canaux publics: <contact page / investor contact / LinkedIn company page>. Sources: <urls>
```

## Validation before finishing

- Folder exists and uses `-` instead of spaces.
- MD file exists inside folder.
- Every section has sources.
- Recent news dates are not older than requested scope unless context requires.
- Contacts section distinguishes official vs third-party confidence.
- If goal tracking is active, call goal completion only after file write and read-back verification.
