Sistema de Pedidos de Restaurante (Serverless)
Um restaurante precisa de um sistema para gerenciar pedidos online, onde:
1. Clientes fazem pedidos via API HTTP.
2. Pedidos são validados e armazenados em um banco de dados NoSQL.
3. A cozinha recebe os pedidos via filas de mensagens.
4. O sistema gera comprovantes em PDF e os armazena em S3.
5. Tudo é executado em um ambiente local com LocalStack.
Serviços Utilizados e Suas Funções
1. API Gateway
○ Função: Expor um endpoint REST (/pedidos) para receber pedidos via
HTTP (POST).
○ Exemplo de Request:
{
 "cliente": "João",
 "itens": ["Pizza", "Refri"],
 "mesa": 5
}
2. Lambda (Criar Pedido)
● Função:
○ Validar o pedido.
○ Salvar no DynamoDB.
○ Enviar o ID do pedido para a fila SQS.
3. DynamoDB
● Tabela: Pedidos
○ Schema: id (chave primária), cliente, itens,
mesa, status.
4. SQS (Fila de Pedidos)
● Função: Garantir que os pedidos sejam processados mesmo se a
cozinha estiver offline.
5. Lambda (Processar Pedido)
● Função:
○ Consumir mensagens da fila SQS.
○ Gerar um comprovante em PDF (simulado).
○ Salvar o PDF no S3.
6. (Requisito Bônus) Notificações via SNS
○ Adicionar SNS ao sistema de pedidos do restaurante para enviar
notificações quando um pedido é concluído (simulando alertas para o
cliente).
○ Exemplo de saída de Notificação
{
 "TopicArn": "arn:aws:sns:us-east-1:000000000000:PedidosConcluidos",
 "Message": "Novo pedido concluído: 12345",
 "Subject": "Pedido Pronto!"
}

Diagrama da solução (Atualizado):
API Gateway: Recebe as requisições.

LambdaCriarPedido: Processa a criação do pedido após receber a requisição do API Gateway.

Conecta-se ao DynamoDB para armazenar informações do pedido.

DynamoDB: Armazena os dados do pedido.

SQS (Simple Queue Service): A LambdaCriarPedido envia uma mensagem para a fila SQS, indicando que um pedido precisa ser processado.

LambdaProcessarPedido: A LambdaProcessarPedido é acionada pela mensagem na fila SQS.

Processa o pedido e interage com o S3 e SNS.

S3 (Simple Storage Service): Usado para armazenar dados relacionados ao pedido, como documentos ou informações complementares.

SNS (Simple Notification Service): Envia uma notificação sobre o pedido.

NotificaçãoParaCozinha: Recebe a notificação através do SNS e é direcionada para o serviço de cozinha.