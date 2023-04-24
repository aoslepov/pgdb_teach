## Работа с postgresql на физическом уровне


<image src="img/server_process.png">

<image src="img/server_process_shared_memory.png">

> первый процесс postgres, запускается при старте сервиса, порождает все остальные процессы, создает shared memory, слушает TCP и Unix socket
