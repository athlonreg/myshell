############################################################
#                   Created by Canvas                      #
#                    Author: Canvas                        #
#             Site: https://blog.iamzhl.top/               #
#               Email: 1143991340@qq.com                   #
############################################################

#!/bin/bash

# 快速搭建hexo博客系统

cd ; npm install -g hexo-cli --save
mkdir blog ; cd blog 
hexo init
npm install 
hexo new "testblog"
hexo clean
hexo g
hexo s