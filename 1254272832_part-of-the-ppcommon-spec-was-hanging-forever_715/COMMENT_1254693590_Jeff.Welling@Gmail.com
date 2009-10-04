The ARGV line that was concating '--readline' was superfluous.  Removing it made no noticable difference, problem solved.
