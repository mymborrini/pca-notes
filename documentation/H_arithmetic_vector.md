# PromQL Vector Matching: group_left, group_right, on(), and ignoring()

This document explains how PromQL performs advanced vector matching using
group_left, group_right, on(), and ignoring().
These features are essential when working with metrics that have different
label cardinalities and must be combined using binary arithmetic.

---

## 1. Why group_left and group_right Exist

By default, PromQL allows only one-to-one matching between time series
during binary operations.
A match is successful only if the label sets of the two series are identical
(except for the metric name).

However, real-world metrics often have different cardinalities:

- one metric exposes a single series per instance
- another metric exposes multiple series per instance (for example, per CPU or per disk)

In these cases, one-to-many or many-to-one matching is required.
This is where group_left and group_right are used.

---

## 2. group_right: Preserving Labels from the Right-Hand Side

### When to use group_right

Use group_right when:
- the right-hand side vector contains more time series
- you want to preserve the extra labels on the right-hand side

### Real-world example

Metrics:
- demo_num_cpus → one series per instance
- demo_cpu_usage_seconds_total → one series per CPU per instance

Goal:
Compute per-CPU usage normalized by the number of CPUs per instance.

Conceptual query:
rate(demo_cpu_usage_seconds_total) divided by demo_num_cpus

Matching behavior:
- match on job and instance
- allow one-to-many matching
- preserve the cpu label from the right-hand side

Result:
Each CPU time series is divided by the number of CPUs for that instance,
and the cpu label remains in the output.

Key takeaway:
group_right preserves the label set of the right-hand side vector.

---

## 3. group_left: Preserving Labels from the Left-Hand Side

### When to use group_left

Use group_left when:
- the left-hand side vector contains more time series
- you want to preserve the extra labels on the left-hand side

### Real-world example

Metrics:
- demo_cpu_usage_seconds_total → per CPU
- demo_cpu_limit → per instance

Goal:
Normalize per-CPU usage by a per-instance CPU limit while keeping the cpu label.

Conceptual query:
rate(demo_cpu_usage_seconds_total) divided by demo_cpu_limit

Matching behavior:
- match on job and instance
- allow many-to-one matching
- preserve the cpu label from the left-hand side

Result:
Each per-CPU series is divided by the instance-level limit,
and the cpu label is preserved.

Key takeaway:
group_left preserves the label set of the left-hand side vector.

---

## 4. The on() Modifier: Explicit Matching Labels

### Purpose of on()

The on() modifier explicitly defines which labels are used for vector matching.
All other labels are ignored during the matching process.

### Real-world example

You want to match metrics only by job and instance,
even if additional labels exist.

Matching rule:
Match only on job and instance.

Effect:
Two time series match if and only if their job and instance labels are equal.

When to use on():
- when you want full control over matching criteria
- when queries are complex or safety-critical
- when avoiding accidental matches is important

---

## 5. The ignoring() Modifier: Excluding Labels from Matching

### Purpose of ignoring()

The ignoring() modifier specifies which labels should be excluded
from the matching process.
All remaining labels are used for matching.

### Real-world example

You want to divide HTTP error request rates by total request rates,
but the status label should not affect matching.

Ignoring rule:
Ignore the status label during matching.

Effect:
Series with different status values can still be matched correctly.

When to use ignoring():
- when only a few labels need to be excluded
- when the majority of labels should still participate in matching

---

## 6. Combining on() with group_right

### Use case

Metrics:
- request_count → per instance
- request_duration → per instance and path

Goal:
Apply a per-instance metric to a per-path metric while preserving path.

Matching strategy:
- use on(job, instance)
- allow one-to-many matching
- preserve right-hand side labels

Result:
Each path-level time series is combined with the instance-level value,
and the path label is preserved.

```promql
rate(demo_cpu_usage_seconds_total{job="lf-app"}[5m])
/
on(job, instance) group_right
demo_num_cpus{job="lf-app"}
```

---

## 7. Combining on() with group_left

### Use case

Metrics:
- cpu_usage → per instance and cpu
- cpu_capacity → per instance

Goal:
Normalize CPU usage per core while preserving cpu labels.

Matching strategy:
- use on(job, instance)
- allow many-to-one matching
- preserve left-hand side labels

Result:
Each per-CPU time series is matched with the instance-level capacity,
and cpu labels remain visible.

```promql
rate(demo_cpu_usage_seconds_total{job="lf-app"}[5m])
/
on(job, instance) group_left
demo_cpu_limit{job="lf-app"}
```

---

## 8. Combining ignoring() with group_right

### Use case

Metrics:
- error_request_rate → includes status label
- total_request_rate → does not include status label

Goal:
Compute error ratios while ignoring status during matching.

Matching strategy:
- ignore status label
- allow one-to-many matching
- preserve right-hand side labels

Result:
Error ratios are computed correctly for all remaining dimensions.

---

## 9. Combining ignoring() with group_left

### Use case

Metrics:
- detailed usage metrics → include extra dimensions
- global limits → fewer dimensions

Goal:
Apply global limits while keeping detailed breakdowns.

Matching strategy:
- ignore non-essential labels
- allow many-to-one matching
- preserve left-hand side labels

Result:
Detailed time series are normalized correctly using global values.

---

## 10. Choosing Between on() and ignoring()

Guidelines:
- Use on() when you want explicit, safe, and predictable matching
- Use ignoring() when excluding a small number of labels is sufficient

Incorrect matching can:
- drop valid time series
- produce misleading results
- silently hide errors

PromQL does not warn about incorrect matching;
the query result may look valid while being semantically wrong.

---

## 11. Summary Rules

- group_right preserves labels from the right-hand side
- group_left preserves labels from the left-hand side
- on() defines exactly which labels must match
- ignoring() defines which labels must not be considered
- group modifiers enable one-to-many and many-to-one matching

Understanding these rules is essential for writing correct,
scalable, and reliable PromQL queries.
