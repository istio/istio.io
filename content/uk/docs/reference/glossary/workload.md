---
title: Робоче навантаження
test: n/a
---

Бінарний файл, розгорнутий [операторами](/docs/reference/glossary/#operator) для надання певної функції застосунку в сервісній мережі. Робоче навантаження має назви, простори імен та унікальні ідентифікатори. Ці властивості доступні в конфігураціях політики та телеметрії за допомогою наступних [атрибутів](/docs/reference/glossary/#attribute):

* `source.workload.name`, `source.workload.namespace`, `source.workload.uid`
* `destination.workload.name`, `destination.workload.namespace`, `destination.workload.uid`

В Kubernetes workload зазвичай відповідає deployment Kubernetes, тоді як [екземпляр робочого навантаження](/docs/reference/glossary/#workload-instance) відповідає окремому [Podʼу](/docs/reference/glossary/#pod), яким управляє deployment.
