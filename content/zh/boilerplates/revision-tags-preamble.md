---
---
在将命名空间移动到新版本时，手动的重新标记命名空间可能既乏味又容易出错。
[修订标签](/zh/docs/reference/commands/istioctl/#istioctl-tag)解决了这个问题。
[修订标签](/zh/docs/reference/commands/istioctl/#istioctl-tag)是指向修订的稳定标识符，可用于避免重新标记命名空间。网格管理员可以简单地更改标签以指向新的修订版，而不是重新标记命名空间。所有标有该标签的命名空间将同时更新。
