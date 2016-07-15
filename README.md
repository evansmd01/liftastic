# LIFTASTIC

## Domain Problems

- for a single exercise on a single training day
    - Week 1 - use 80% of 1RM
    - Week 2 - increase by 5% (unless you didn't finish week 1)
    - Week 3 - deload week, use 70% of 1RM
    - Week 4 - back to increase by 5%, but increase based on week 2, not previous week
- Additional considerations
    - If you skip a week (or fail to complete it), the next week should use the previous weeks prescription
        - unless the skipped week was a deload
    - If you skip part of an day, like you completed 1st exercise, but not second
        - next week should increase the 1st exercise
        - but use previous weeks prescription for second exercise
            - unless it was a deload
    - Supersets (2 or more exercises with alternating sets)
    - Alternating weeks
        - Example
            - Week 1 - Squat
            - Week 2 - Deadlift
            - Week 3 - Squat (increase week 1)
            - Week 4 - Deadlift (increase week2)
    - Training phases
        - Example
            - Week 1 - Squats     Bench
            - Week 1 - Squats     Bench
            - Week 1 - Squats     Overhead Press
            - Week 1 - Squats     Overhead Press
    - Increase reps instead of weight
    - Increase sets instead of weight

## Domain Model
```
Prescriptions
WM = working max = 1 rep max at time of first week
intensity(p) = percentage p of WM
Inc(n, i) = W(n) ? W(n) + i : use W(n)’s prescription

example
W1: 70%
W2: W1 ? W1 + 5 : W1
W3: W2 ? W2 + 5 : W2
W4: 60%
W5: W3 ? W3 + 5 : W3
W6: W5 ? W5 + 5 : W5

Day 1
Back Squat
 			
W1	        3 reps @ 70% WM		
W2	if W1?  3 reps @ 75% WM     5 reps @ 60% WM	    
W3	if W2?  3 reps @ 80% WM     5 reps @ 65% WM     8 reps @ 50% WM
W4              3 reps @ 60% WM				
W5	if W3?  3 reps @ 85% WM     5 reps @ 70% WM     8 reps @ 55% WM
W6	if W5?  3 reps @ 90% WM     5 reps @ 75% WM     8 reps @ 60% WM 
```

## Domain Aggregate Roots

```
Training Program
    Training Day 1 ...
    Training Day 2 ...
    Training Day 3
        desc "max effort"
        prescription group 1
            exercise prescription ...
        prescription group 2 ...
            description "superset"
            exercise prescription 1 ...
            exercise prescription 2
                exercise id "squats"
                week prescription 1
                    set prescription 1 ...
                        intensity 90%
                        reps 3
                    set prescription 2 ...
                        intensity 70%
                        reps 6
                week prescription 2
                    based on week 1
                    set prescription 1 ...
                        intensity 75%
                        reps 3
                    set prescription 2 ...
                        intensity 75%
                        reps 6
                week prescription 3
                    description "deload"
                    base on week nil
                    set prescription 1 ...
                        intensity 70%
                        reps 3
                    set prescription 2 ...
                        intensity 50%
                        reps 6
                week prescription 4
                    based on week 2
                    set prescription 1 ...
                        intensity 80%
                        reps 3
                    set prescription 2 ...
                        intensity 80%
                        reps 6

Training History
    user
    exercise
    units
    date
    prescription identifier
        program id
        day index
        group index
        exercise index
        week index
    completed as prescribed?
    sets
        set 1 ...
        set 2
            reps 3
            weight 100

Training Session
    session group 1 ...
    session group 2
        exercise 1 ...
        exercise 2
            exercise "squat"
            set 1 ...
            set 2
                reps 3
                weight 100
```