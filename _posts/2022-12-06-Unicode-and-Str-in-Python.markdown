---
layout:     post
title:      "Python中的unicode与str"
subtitle:   "unicode and str in python"
date:       2022-12-06
author:     "wykxwyc"
header-img: "img/post-bg-common-seiigi-punch.jpg"
tags:
    - Python
    - unicode
    - 字符串
---

___目录___

* content
{:toc}

---

### 问题的出现
一个日志的函数出现了报错，报错内容如下：      

```
[LOG] ERROR [findAvatarNameByNid] nid(%s), name(%s), ret(%s) (4093364685, u'\u8fd9\u662f\u6635\u79f0id~', "{'aid': u'041101', '_id': u'YlP2NQgI0GG9D97W', 'nid': 4093364685L, 'name': u'\\u8fd9\\u662f\\u6635\\u79f0id~', 'username': u'', 'login_channel': u'', 'app_channel': u'app_channel', 'alpha_expire_ts': ''}")
```

其实是日志打印出错了，日志函数是这样定义的：      

```python
def _log_with_timestamp(level, msg, args, **kwargs):
    try:
        ct = time.time()
        lt = time.localtime(ct)
        print "%04d-%02d-%02d %02d:%02d:%02d.%03d\t%-12.12s\t%5d\t%-5.5s\t%-16.16s\t%s %s" % (
                lt.tm_year, lt.tm_mon, lt.tm_mday, lt.tm_hour, lt.tm_min, lt.tm_sec, (ct - int(ct)) * 1000,
                TAG, PID, level, NAME, msg % args, kwargs and kwargs or "")
    except Exception:
        print '[LOG] ERROR', msg, args, kwargs and kwargs or ""
```

出错的Exception内容为：      

```
UnicodeEncodeError('ascii', u"[findAvatarNameByNid] nid(4093364685), name(\u8fd9\u662f\u6635\u79f0id~), ret({'aid': u'041101', '_id': u'YlP2NQgI0GG9D97W', 'nid': 4093364685L, 'name': u'\\u8fd9\\u662f\\u6635\\u79f0id~', 'username': u'', 'login_channel': u'', 'app_channel': u'app_channel', 'alpha_expire_ts': ''})", 44, 48, 'ordinal not in range(128)')
```

因为print函数中， msg % args 会把参数转义，而name是unicode，所以转义之后 msg % args整体就变成了一个unicode，接下来需要把这个整体转义到%s里面。此处转义会直接使用str()函数，但是其中的name(\u8fd9\u662f\u6635\u79f0id~)部分使用str函数,因为ascii无法解码导致出错了，因此有这个报错。      

### ascii, unicode与utf-8
Python的诞生比Unicode标准发布的时间还要早，所以最早的Python只支持ASCII编码,Python在后来添加了对Unicode的支持，以Unicode表示的字符串用u'...'表示。      
**unicode**：加入多国字符，一般是2个字节表示一个字符，偏僻字用4个字节。缺点：浪费存储空间。 
**ascii**：最早的，容量最小的编码方式。1个字节表示一个字符。         
**utf-8**：为了解决浪费空间的问题，常用的英文字母被编码成1个字节，汉字通常是3个字节，只有很生僻的字符才会被编码成4-6个字节。     

保存：Python源代码也是一个文本文件，所以，当你的源代码中包含中文的时候，在保存源代码时，就需要务必指定保存为UTF-8编码。      
读取：当Python解释器读取源代码时，为了让它按UTF-8编码读取，我们通常在文件开头（第一行或第二行）写上这一行行`# -*- coding: utf-8 *-`      

一个unicode编码与utf-8编码之间的转换：      

```python
# -*- coding: utf-8 -*-
import re
import traceback
import sys
import time
import os


def unicode2utf8():
	print repr(u'abc'.encode('utf-8'))
	print repr(u'中文'.encode('utf-8'))

def utf82unicode():
	print repr('abc'.decode('utf-8'))
	print repr('\xe4\xb8\xad\xe6\x96\x87'.decode('utf-8'))
	print repr('中文'.decode('utf-8'))


if __name__ == "__main__":
	print "========================="
	print sys.getdefaultencoding()
	print "========================="
	unicode2utf8()
	print "========================="
	utf82unicode()
	print "========================="
```

输出的结果为：      

```
=========================
ascii
=========================
'abc'
'\xe4\xb8\xad\xe6\x96\x87'
=========================
u'abc'
u'\u4e2d\u6587'
u'\u4e2d\u6587'
=========================
```

### Python3中的bytes与unicode的转换
python发展过程中，最初设计使用ASCII编码，后来扩充到Latin-1， 再后来扩展到unicode。       
unicode首先使用2字节代表一个字符，再后来扩展到4字节代表一个字符，空间有浪费，所以有了utf-8这种变长的编码方式。      
bytes -- decode --> unicode      
bytes <-- encode -- unicode      

### Python3与python2的文件区别
python *.py --> .pyc      
pyhton -O   --> .pyo      
pyhton -O   --> .pyo      

Python3中取消了pyo文件，统一使用pyc      
Python3      --> .pyc      

### 判断unicode是不是控制字符      
判断字符串s中是否有控制字符, s为unicode字符串    
通过unicodedata.category对unicode字符进行分类，对于控制字符，分类信息以'C'开头      
```python
import unicodedata
s = u'\0'
for ch in s:
    if unicodedata.category(ch)[0] == "C":
        print True
```


### 参考文献    
1.[https://pyformat.info/](https://pyformat.info/)      
2.[unicode控制字符串判断](https://docs.python.org/2/library/unicodedata.html)      
3.[python文档string-format](https://docs.python.org/2/library/stdtypes.html#string-formatting)      
4.[python2 编码问题详解](https://www.cnblogs.com/weaming/p/4956181.html)      
