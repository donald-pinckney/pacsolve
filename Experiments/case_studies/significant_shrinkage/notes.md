# Case Study on `utils`

When solving `utils` using Vanilla NPM, we get 40 nodes. With MinNPM:

```bash
npm install --rosette --ignore-scripts --consistency npm --minimize min_num_deps,min_oldness
```
we get 24 nodes. Why?

The root package depends on `"which-typed-array": "^1.1.2"`. 
Vanilla NPM chooses the most recent version (1.1.7), which then forces it to choose a 
newer version of `es-abstract` (1.19.1). However, MinNPM chooses an older version of
`which-typed-array` (1.1.2), and then chooses an older version of `es-abstract` (1.17.5).
From there, the dependencies on the Vanilla NPM side explode. 
Version 1.19.1 of `es-abstract` has 20 dependencies, whereas version 1.17.5
only has 11 dependencies.