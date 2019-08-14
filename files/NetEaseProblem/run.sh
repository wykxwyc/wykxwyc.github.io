#!/bin/bash 

num=1
for((i=1;i<=1000;i++)); 
do  
j=$(echo "$num*0.0+$i*0.001"|bc)
# let "num=num + add"
echo "0"$j
cnt="0"$j
# echo $cnt>>text
res=$( echo $j |./guess_linux )
echo $res
echo $res>>text
done
