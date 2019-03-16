---
layout:     post
title:      "Qt信号与槽机制是如何工作的"
subtitle:   "How Qt Signals and Slots Work"
date:       2019-02-26
author:     "wykxwyc"
header-img: "img/post-bg-how-qt-signals.jpg"
tags:
    - C++
    - Qt
---
> Qt is well known for its signals and slots mechanism. But how does it work?
> 
> 原文链接：[woboq](https://woboq.com/blog/how-qt-signals-slots-work.html)
> 
> 参考译文链接：[NewThinker_Jiwey@CSDN](https://blog.csdn.net/newthinker_wei/article/details/22701695)

#### Signals and Slots
首先来看一下官方给出的[示例](https://doc.qt.io/archives/qt-4.8/signalsandslots.html "Signals & Slots")是怎样的？
它的头文件是这样的：

```cpp
class Counter : public QObject
{
    Q_OBJECT
    int m_value;
public:
    int value() const { return m_value; }
public slots:
    void setValue(int value);
signals:
    void valueChanged(int newValue);
};
```
在某个.cpp文件中，`setValue()`函数的实现是这样的：
```cpp
void Counter::setValue(int value)
{
    if (value != m_value) {
        m_value = value;
        emit valueChanged(value);
    }
}
```
然后如果有人想要使用`Counter`对象，他就可以这样使用：
```cpp
  Counter a, b;
  QObject::connect(&a, SIGNAL(valueChanged(int)),
                   &b, SLOT(setValue(int)));

  a.setValue(12);  // a.value() == 12, b.value() == 12
```
这是从1992年Qt最初阶段开始就沿用下来而几乎没有变过的原始语法。

虽然基本的API并没有怎么变过，但它的实现方式却变了几次。很多新特性被添加了进来，底层的实现也发生了很多变化。不过这里面并没有什么神奇的难以理解的东西，本文会展示这究竟是如何工作的.


#### MOC, the Meta Object Compiler
Qt的信号与槽和属性系统都基于其能在运行时省察对象的能力。实时省察的意思就是指它能够在运行时列出一个对象有哪些方法和属性，以及关于他们的各种信息（例如他们的参数的类型）。
如果没有实时省察这个功能，`QtScript`和`QML`就基本不可能实现了。

C++语言本省不支持实时省察功能。因此Qt搞了一个工具来提供这个功能。这个工具就叫`MOC`。它是一个*代码生成器*而不是一个预处理器（尽管很多人喜欢这么叫它）。

它解析头文件，然后产生一个额外的C++文件用于和其他程序一起进行编译。这个产生的额外的C++文件就包含实时省察所需要的各种信息。

Qt有时候就是因为这个额外的代码生成器影响了语言的纯正性，因为广受批判。对于这种争议，这里不作讨论，与这种争议有关的回应可以参看[这里](https://doc.qt.io/archives/qt-4.8/templates.html "Why Doesn't Qt Use Templates for Signals and Slots?")。这个代码生成器本身并没有什么错，而且`MOC`的十分有用。


#### Magic Macros
你能认出这些*关键字*中不是C++关键字的吗？`signals`, `slots`, `Q_OBJECT`, `emit`, `SIGNAL`, `SLOT`。这些都是Qt对C++的扩展。他们其实都是一些简单的宏，定义在[qobjectdefs.h](https://code.woboq.org/qt5/qtbase/src/corelib/kernel/qobjectdefs.h.html#66)中：
```
#define signals public
#define slots /* nothing */
```

信号与槽其实只是简单的函数，编译器会像处理任何其他函数一样对待他们。但是这两个宏还有另一个功能：`MOC`能够看到他们。

`Signals`在Qt4及以前是`protected`的。但他们在Qt5以后成为了`public`，为了能够使[新的语法](https://woboq.com/blog/new-signals-slots-syntax-in-qt5.html)成立。

```
#define Q_OBJECT \
public: \
    static const QMetaObject staticMetaObject; \
    virtual const QMetaObject *metaObject() const; \
    virtual void *qt_metacast(const char *); \
    virtual int qt_metacall(QMetaObject::Call, int, void **); \
    QT_TR_FUNCTIONS /* translations helper */ \
private: \
    Q_DECL_HIDDEN static void qt_static_metacall(QObject *, QMetaObject::Call, int, void **);
```
`Q_OBJECT`定义了一连串的函数和静态`QMetaObject`。这些函数在`MOC`产生的文件中被实现。

```cpp
#define emit /* nothing */
```
`emit`是一个空的宏。它甚至不被`MOC`解析。也就是说`emit`屁用没有，除了能对开发者起到点提示作用外。

```
Q_CORE_EXPORT const char *qFlagLocation(const char *method);
#ifndef QT_NO_DEBUG
# define QLOCATION "\0" __FILE__ ":" QTOSTRING(__LINE__)
# define SLOT(a)     qFlagLocation("1"#a QLOCATION)
# define SIGNAL(a)   qFlagLocation("2"#a QLOCATION)
#else
# define SLOT(a)     "1"#a
# define SIGNAL(a)   "2"#a
#endif
```
上面这些宏使用了预处理器将参数转换成了一个字符串，然后在前面加了一个代号（code）。

在调试模式下，如果信号连接没有起作用，我们会对吧文件位置和这个字符串都提示出来作为警告信息。这个功能在Qt4.5中以兼容的方式被加进来。为了知道哪个字符串有着行信息（line information），我们使用`qFlagLocation`,这个函数会将对应代码的地址信息注册到一个有两个入口的表里。

#### MOC Generated Code
我们现在就来看看Qt5的moc生成的部分代码。

##### The QMetaObject
```
const QMetaObject Counter::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_Counter.data,
      qt_meta_data_Counter,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *Counter::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}
```
这里我们看到了`Counter::metaObject()`和`Counter::staticMetaObject`的实现。他们在`Q_OBJECT`中声明。`QObject::d_ptr->metaObject`只被动态元对象使用（QML对象），所以总的来说，虚函数`metaObject()`只返回了类的`staticMetaObject`。

`staticMetaObject`被构造成为只读数据。`QMetaObject`在[qobjectdefs.h](https://code.woboq.org/qt5/qtbase/src/corelib/kernel/qobjectdefs.h.html#QMetaObject)中定义：

```
struct QMetaObject
{
    /* ... Skiped all the public functions ... */

    enum Call { InvokeMetaMethod, ReadProperty, WriteProperty, /*...*/ };

    struct { // private data
        const QMetaObject *superdata;
        const QByteArrayData *stringdata;
        const uint *data;
        typedef void (*StaticMetacallFunction)(QObject *, QMetaObject::Call, int, void **);
        StaticMetacallFunction static_metacall;
        const QMetaObject **relatedMetaObjects;
        void *extradata; //reserved for future use
    } d;
};
```
代码中用的`d`是为了表明那些数据都本应为私有的。然而他们并没有成为私有的是为了保持它为POD和允许静态初始化（在C++中，我们把传统的C风格的struct叫做POD（Plain Old Data），字面意思古老的普通的结构体）。

`QMetaObject`会用父对象的元对象初始化（这里指`QObject::staticMetaObject`）,而`superdata`,`stringdata` 和 `data`会被其他数据初始化，这些数据在文章后面继续讨论。`static_metacall`是一个被初始化为`Counter::qt_static_metacall`的函数指针。



##### Introspection Tables
首先让我们来分析一下QMetaObject的整型数据。
```
static const uint qt_meta_data_Counter[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       2,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   24,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
       4,    1,   27,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void, QMetaType::Int,    3,

 // slots: parameters
    QMetaType::Void, QMetaType::Int,    5,

       0        // eod
};
```
前面13个（注：这里应该是作者数错了，应该是14个吧？）组成了结构体的头信息。对于有两列的那些数据，第一列表示某一类项目的个数，第二列表示这一类项目的描述信息开始于这个数组中的哪个位置（索引值）。
这里，我们的`Counter`类有两个方法，并且关于方法的描述信息开始于第14(注：如果第一个是0的话，是14，如果从1开始算，则是15)个int数据。

每个方法的描述信息由5个int型数据组成。第一个整型数代表方法名，它的值是该方法名（注：方法名就是个字符串）在字符串表中的索引位置（之后会介绍字符串表）。第二个整数表示该方法所需参数的个数，后面紧跟的第三个数就是关于参数的描述（注：它表示与参数相关的描述信息开始于本数组中的哪个位置，也是个索引）。我们现在先忽略掉tag和flags。对于每个函数，Moc还会保存它的返回类型、每个参数的类型、以及参数的名称。



##### String Table
```
struct qt_meta_stringdata_Counter_t {
    QByteArrayData data[6];
    char stringdata0[46];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_Counter_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_Counter_t qt_meta_stringdata_Counter = {
    {
		QT_MOC_LITERAL(0, 0, 7), // "Counter"
		QT_MOC_LITERAL(1, 8, 12), // "valueChanged"
		QT_MOC_LITERAL(2, 21, 0), // ""
		QT_MOC_LITERAL(3, 22, 8), // "newValue"
		QT_MOC_LITERAL(4, 31, 8), // "setValue"
		QT_MOC_LITERAL(5, 40, 5) // "value"
    },
    "Counter\0valueChanged\0\0newValue\0setValue\0"
    "value"
};
#undef QT_MOC_LITERAL
```
这主要就是一个`QByteArray`的静态数组。`QT_MOC_LITERAL`这个宏可以创建一个静态的`QByteArray`，其数据就是参考的在它下面的对应索引处的字符串。



##### Signals
`MOC`也实现了信号`signals`（注：signals其实就是public，而我们在开发中并不写信号的定义，这是因为这些都由MOC来完成）。所有的信号都是很简单的函数而已，他们只是为参数创建一个指针数组并传递给`QMetaObject::activate`函数。指针数组的第一个元素是属于返回值的。在我们的例子中将它设置为了0，这是因为我们的返回类型是`void`。
传递给`activate`函数的第3个参数﻿﻿是信号的索引（在这里，该索引为0）。
```
// SIGNAL 0
void Counter::valueChanged(int _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
```


##### Calling a Slot
借助于`qt_static_metacall`也可以通过槽函数的索引来调用槽函数。
```cpp
void Counter::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Q_ASSERT(staticMetaObject.cast(_o));
        Counter *_t = static_cast<Counter *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->valueChanged((*reinterpret_cast< int(*)>(_a[1]))); break;
        case 1: _t->setValue((*reinterpret_cast< int(*)>(_a[1]))); break;
        default: ;
        }
}
```
函数中的指针数组与在上面介绍signal时的那个函数中的指针数组格式相同。只不过这里没有用到`_a[0]`，因为这里所有的函数都是返回void。



#### A Note About Indexes
在每个QMetaObject中，对象的槽、信号和其他一些`可唤醒`的成员函数都被分配了一个索引，这些索引值从0开始。他们的顺序是signals在最前面，其次是slots，最后是其他函数。这个索引在内部被称为`相对索引`。但这里不包含父类的索引（注：也就是不包含父类的signals，slots和其他方法）。

但是通常，我们不是想知道相对索引，而是想知道在包含了从父类和祖宗类中继承来的所有方法后的绝对索引。为了得到这个索引，我们只需要在相关索引（relative index）上加上一个偏移量就可以得到绝对索引absolute index了。这个绝对索引就是在Qt的API中使用的，像`QMetaObject::indexOf{Signal,Slot,Method}`这样的函数返回的就是绝对索引。

另外，在信号槽的连接机制中还要用到一个关于信号的向量索引。这样的索引表中如果把槽也包含进来的话槽会造成向量的浪费，而一般槽的数量又要比信号多。所以从Qt4.6开始，Qt内部又多出了一个专门的信号索引signal index ，它是一个只包含了信号的索引表。

在用Qt开发的时候，我们只需要关心绝对索引就行。不过在浏览Qt源码的时候，要留意这三种索引的不同。



#### How Connecting Works.
在进行连接时，Qt会做的第一件事就是去找到信号与槽函数的索引。Qt会在元对象(meta object)的字符串表中查找对应的索引。

然后一个`QObjectPrivate::Connection`的对象会被创造并添加到内部链表中来。

对于每个连接，哪些信息需要被存储进来？我们需要一种能根据信号索引signal index快速访问到对应的connection的方法。因为可能会同时有不止一个槽连接到同一个信号上，所以每一个信号都要有一个槽列表。每个connection必须包含接收对象(的指针)以及被连接的槽的索引。我们也希望当接收对象呗销毁时连接也会被自动销毁，因此每个接收对象（receiver）需要知道谁连着它以便于它可以清除这些连接（connection）。

这是在[qobject_p.h](https://code.woboq.org/qt5/qtbase/src/corelib/kernel/qobject_p.h.html#QObjectPrivate::Connection)中定义的`QObjectPrivate::Connection`。

```
struct QObjectPrivate::Connection
{
    QObject *sender;
    QObject *receiver;
    union {
        StaticMetaCallFunction callFunction;
        QtPrivate::QSlotObjectBase *slotObj;
    };
    // The next pointer for the singly-linked ConnectionList
    Connection *nextConnectionList;
    //senders linked list
    Connection *next;
    Connection **prev;
    QAtomicPointer<const int> argumentTypes;
    QAtomicInt ref_;
    ushort method_offset;
    ushort method_relative;
    uint signal_index : 27; // In signal range (see QObjectPrivate::signalIndex())
    ushort connectionType : 3; // 0 == auto, 1 == direct, 2 == queued, 4 == blocking
    ushort isSlotObject : 1;
    ushort ownArgumentTypes : 1;
    Connection() : nextConnectionList(0), ref_(2), ownArgumentTypes(true) {
        //ref_ is 2 for the use in the internal lists, and for the use in QMetaObject::Connection
    }
    ~Connection();
    int method() const { return method_offset + method_relative; }
    void ref() { ref_.ref(); }
    void deref() {
        if (!ref_.deref()) {
            Q_ASSERT(!receiver);
            delete this;
        }
    }
};
```
每一个对象有一个连接列表（connection vector）。每一个信号有一个 QObjectPrivate::Connection的链表，这个vector就是与这些链表相关联的。

每一个对象还有一个反向链表，它包含了连接到这个对象的所有connection，这样可以实现连接的自动清除。而且这个反向链表是一个双重链表。

![qobject_connection](/img/in-post/post-how-qt-signals/qobject_connection.png)

之所以使用链表，是因为链表能够快速添加和删除对象。这个功能通过指向前/后节点的指针在`QObjectPrivate::Connection`类内实现。

注意senderList的prev指针是一个“指针的指针”。这是因为我们不是真的要指向前一个节点，而是要指向一个指向前节点的指针。这个“指针的指针”只有在销毁连接时才用到，而且不要用它重复往回迭代。这样设计可以不用对链表的首结点做特殊处理。

![qobject_connection_node](/img/in-post/post-how-qt-signals/qobject_connection_node.png)



#### Signal Emission
当我们调用一个信号时，我们会发现这个信号会调用`MOC`产生的代码，这些代码里面调用了`QMetaObject::activate`。

下面是一段截取自[qobject.cpp](https://code.woboq.org/qt5/qtbase/src/corelib/kernel/qobject.cpp.html#_ZN11QMetaObject8activateEP7QObjectPKS_iPPv),并经过注释的代码。

```
void QMetaObject::activate(QObject *sender, const QMetaObject *m, int local_signal_index,
                           void **argv)
{
    activate(sender, QMetaObjectPrivate::signalOffset(m), local_signal_index, argv);
    /* We just forward to the next function here. We pass the signal offset of
     * the meta object rather than the QMetaObject itself
     * It is split into two functions because QML internals will call the later. */
}

void QMetaObject::activate(QObject *sender, int signalOffset, int local_signal_index, void **argv)
{
    int signal_index = signalOffset + local_signal_index;

    /* The first thing we do is quickly check a bit-mask of 64 bits. If it is 0,
     * we are sure there is nothing connected to this signal, and we can return
     * quickly, which means emitting a signal connected to no slot is extremely
     * fast. */
    if (!sender->d_func()->isSignalConnected(signal_index))
        return; // nothing connected to these signals, and no spy

    /* ... Skipped some debugging and QML hooks, and some sanity check ... */

    /* We lock a mutex because all operations in the connectionLists are thread safe */
    QMutexLocker locker(signalSlotLock(sender));

    /* Get the ConnectionList for this signal.  I simplified a bit here. The real code
     * also refcount the list and do sanity checks */
    QObjectConnectionListVector *connectionLists = sender->d_func()->connectionLists;
    const QObjectPrivate::ConnectionList *list =
        &connectionLists->at(signal_index);

    QObjectPrivate::Connection *c = list->first;
    if (!c) continue;
    // We need to check against last here to ensure that signals added
    // during the signal emission are not emitted in this emission.
    QObjectPrivate::Connection *last = list->last;

    /* Now iterates, for each slot */
    do {
        if (!c->receiver)
            continue;

        QObject * const receiver = c->receiver;
        const bool receiverInSameThread = QThread::currentThreadId() == receiver->d_func()->threadData->threadId;

        // determine if this connection should be sent immediately or
        // put into the event queue
        if ((c->connectionType == Qt::AutoConnection && !receiverInSameThread)
            || (c->connectionType == Qt::QueuedConnection)) {
            /* Will basically copy the argument and post an event */
            queued_activate(sender, signal_index, c, argv);
            continue;
        } else if (c->connectionType == Qt::BlockingQueuedConnection) {
            /* ... Skipped ... */
            continue;
        }

        /* Helper struct that sets the sender() (and reset it backs when it
         * goes out of scope */
        QConnectionSenderSwitcher sw;
        if (receiverInSameThread)
            sw.switchSender(receiver, sender, signal_index);

        const QObjectPrivate::StaticMetaCallFunction callFunction = c->callFunction;
        const int method_relative = c->method_relative;
        if (c->isSlotObject) {
            /* ... Skipped....  Qt5-style connection to function pointer */
        } else if (callFunction && c->method_offset <= receiver->metaObject()->methodOffset()) {
            /* If we have a callFunction (a pointer to the qt_static_metacall
             * generated by moc) we will call it. We also need to check the
             * saved metodOffset is still valid (we could be called from the
             * destructor) */
            locker.unlock(); // We must not keep the lock while calling use code
            callFunction(receiver, QMetaObject::InvokeMetaMethod, method_relative, argv);
            locker.relock();
        } else {
            /* Fallback for dynamic objects */
            const int method = method_relative + c->method_offset;
            locker.unlock();
            metacall(receiver, QMetaObject::InvokeMetaMethod, method, argv);
            locker.relock();
        }

        // Check if the object was not deleted by the slot
        if (connectionLists->orphaned) break;
    } while (c != last && (c = c->nextConnectionList) != 0);
}
```


#### Conclusion
这篇文章讲了连接是如何产生的以及信号和槽函数是如何发射的。但是这里没有介绍Qt5的新语法及其实现，在下一篇文章中会对此进行介绍。



