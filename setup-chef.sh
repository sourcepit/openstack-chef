#!/bin/bash

echo ""
echo "Installing Ruby..."
echo "********************************************************************************************"
echo ""
yum install -y ruby ruby-devel rubygems gcc-c++ autoconf
echo ""
echo "********************************************************************************************"
echo ""

echo ""
echo "Installing Berkshelf..."
echo "********************************************************************************************"
echo ""
gem install ridley:4.1.1
gem install retryable:1.3.6
gem install berkshelf:3.2.2 -n /usr/bin
echo ""
echo "********************************************************************************************"
echo ""

echo ""
echo "Installing Chef..."
echo "********************************************************************************************"
echo ""
curl -sL https://www.opscode.com/chef/install.sh | sudo bash -s -- -v 12.0.3
echo ""
echo "********************************************************************************************"
echo ""