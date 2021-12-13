# How to find root cause with PIP mode failure:

1. Run with NPM consistency, minimize num_duplicates
2. Search the solution for co-installations
3. Investigate what forced those co-installations


# Example: terser@5.9.0

## Proof of unsolveability:

`terser@.5.9.0` dependencies:

```js
dependencies: {
  commander: '^2.20.0',
  'source-map': '~0.7.2',
  'source-map-support': '~0.5.20'
},
```

Based on `'source-map': '~0.7.2'`, the only versions we can choose of `source-map` at the root are: `0.7.0`, `0.7.1`, `0.7.2`, `0.7.3`.

Now let's look at `source-map-support`. The only versions
we can choose of `source-map-support` are `0.5.20` and `0.5.21`. Both versions have a dependency of:

```js
'source-map': '^0.6.0'
```

The only versions we can choose of `source-map` within `source-map-support` are `0.6.0`
and `0.6.1`.

In conclusion, we forced to include two copies of `source-map`:
1. At the root, we can choose from: `0.7.0`, `0.7.1`, `0.7.2`, `0.7.3`
2. Within `source-map-support`, we can choose from: `0.6.0`, `0.6.1`

It is impossible to unify these two copies. QED.


## Solution
This case study illustrates a deeper problem with the `source-map` and `source-map-support` packages. The most recent version of `source-map-support`
forces you to use an older version of `source-map` (`0.6.1`) than what is
available (`0.7.3`). The best solution would be for `source-map-support` to
support newer versions of `source-map`. However, if that is not possible,
one could accept using an older version of `source-map` (`0.6.1`) *consistently*,
by changng the root dependencies to allow older versions of `source-map`:

```js
'source-map': '~0.7.2',   ----(change to)---->  'source-map': '^0.6.0',
```






