for i in $(seq 30)
do
  echo -n $i:
  cut -d , -f $i public_leaderboard-f.csv >column$i
  sort -u column$i | wc -l
done
