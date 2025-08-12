#!/bin/bash

# Set proper environment for Ruby execution
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export GEM_HOME=/home/ajey/workspace/gate-wireguard/vendor/bundle
export GEM_PATH=/home/ajey/workspace/gate-wireguard/vendor/bundle

echo "Running RuboCop with proper environment..."
bundle exec rubocop --format simple --display-cop-names > rubocop_final.txt 2>&1

echo "RuboCop analysis complete. Results saved to rubocop_final.txt"
echo "First 20 lines of output:"
head -20 rubocop_final.txt

echo ""
echo "Last 10 lines of output:"
tail -10 rubocop_final.txt

echo ""
echo "Total lines in output:"
wc -l rubocop_final.txt
