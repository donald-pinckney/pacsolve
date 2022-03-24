# Failure Categorization for Vanilla NPM

## Peer Dependencies (ERESOLVE)
- https-proxy-agent
- regexpp
- file-uri-to-path
- request
- date-fns
- @tootallnate_once
- agent-base
- saxes
- terser-webpack-plugin
- http-proxy-agent
- tsutils
- whatwg-fetch
- babel-loader
- ts-node
- eslint-utils
- rxjs
- abab
- html-entities

> PacSolve succeeds because right now we don't solve peer deps.


## Unsolveable Dev / Optional Deps (ETARGET)
- jest-matcher-utils
- jest-haste-map
- jest-diff

> PacSolve succeeds because right now we don't solve dev / optional deps.


## EUNSUPPORTEDPROTOCOL (Some junk dependency format)
- jsdom

> I think PacSolve succeeds here since it will skip over the junk, 
> and gather up all the non-junk, and manages to find a successful solve among the non-junk.
> It is **good** that PacSolve succeeds here.

## E404 (Dependency via GitHub URL 404s)
- fast-levenshtein

> PacSolve succeeds for the same reason as in EUNSUPPORTEDPROTOCOL
> It is **good** that PacSolve succeeds here.


## Spurious Error on Discovery (Vanilla NPM Succeeded on Mac)
- decamelize (empty solve, but ok)


