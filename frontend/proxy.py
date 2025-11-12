#!/usr/bin/env python3
"""
Proxy server para o frontend acessar o API Gateway do LocalStack.
Automaticamente descobre o API ID e redireciona as requisições.
"""

import json
import subprocess
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler
import urllib.request
import urllib.error

PORT = 8080
LOCALSTACK_ENDPOINT = "http://localhost:4566"
API_NAME = "pedidos-api"
SNS_TOPIC_NAME = "PedidosConcluidos"  # Nome do tópico SNS

def get_api_id():
    """Descobre o API ID do LocalStack automaticamente."""
    try:
        # Configurar variáveis de ambiente para LocalStack
        import os
        env = os.environ.copy()
        env['AWS_ACCESS_KEY_ID'] = 'test'
        env['AWS_SECRET_ACCESS_KEY'] = 'test'
        env['AWS_DEFAULT_REGION'] = 'us-east-1'
        
        # Executar comando AWS CLI
        result = subprocess.run(
            [
                "aws", "--endpoint-url", LOCALSTACK_ENDPOINT,
                "apigateway", "get-rest-apis",
                "--region", "us-east-1",
                "--query", f"items[?name=='{API_NAME}'].id",
                "--output", "text"
            ],
            capture_output=True,
            text=True,
            check=True,
            env=env
        )
        
        api_id = result.stdout.strip()
        if not api_id:
            print(f"❌ API '{API_NAME}' não encontrada no LocalStack")
            return None
        
        print(f"✅ API ID encontrado: {api_id}")
        return api_id
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Erro ao buscar API ID: {e}")
        print(f"   stderr: {e.stderr}")
        return None
    except FileNotFoundError:
        print("❌ AWS CLI não encontrado. Instale o AWS CLI para usar este proxy.")
        return None


class ProxyHandler(SimpleHTTPRequestHandler):
    """Handler que redireciona requisições para o API Gateway."""
    
    api_id = None
    
    def do_OPTIONS(self):
        """Responder a requisições OPTIONS (CORS preflight)."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        """Proxy para requisições GET."""
        if self.path.startswith('/api/'):
            self.proxy_request('GET')
        elif self.path == '/sns/messages':
            self.get_sns_messages()
        elif self.path == '/sns/published':
            self.get_published_sns_messages()
        else:
            # Servir arquivos estáticos (HTML, CSS, JS)
            super().do_GET()
    
    def do_POST(self):
        """Proxy para requisições POST."""
        if self.path.startswith('/api/'):
            self.proxy_request('POST')
        else:
            self.send_error(404)
    
    def proxy_request(self, method):
        """Redireciona a requisição para o API Gateway."""
        if not self.api_id:
            self.send_error(503, "API Gateway não configurado")
            return
        
        # Remover /api/ do path
        api_path = self.path[4:]  # Remove '/api'
        
        # Construir URL do API Gateway
        url = f"{LOCALSTACK_ENDPOINT}/restapis/{self.api_id}/prod/_user_request_{api_path}"
        
        try:
            # Ler body se for POST
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None
            
            # Fazer requisição para o API Gateway
            headers = {'Content-Type': 'application/json'} if body else {}
            req = urllib.request.Request(url, data=body, headers=headers, method=method)
            
            with urllib.request.urlopen(req) as response:
                # Ler resposta
                response_body = response.read()
                
                # Enviar resposta
                self.send_response(response.status)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(response_body)
                
        except urllib.error.HTTPError as e:
            # Erro HTTP da API
            error_body = e.read()
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(error_body)
            
        except Exception as e:
            # Erro inesperado
            self.send_error(500, f"Erro no proxy: {str(e)}")
    
    def get_sns_messages(self):
        """Busca atributos das últimas publicações SNS no CloudWatch Logs."""
        try:
            import os
            env = os.environ.copy()
            env['AWS_ACCESS_KEY_ID'] = 'test'
            env['AWS_SECRET_ACCESS_KEY'] = 'test'
            env['AWS_DEFAULT_REGION'] = 'us-east-1'
            
            # Buscar mensagens do tópico SNS via CloudWatch Logs
            # No LocalStack, as mensagens SNS ficam nos logs
            result = subprocess.run(
                [
                    "aws", "--endpoint-url", LOCALSTACK_ENDPOINT,
                    "sns", "list-topics",
                    "--region", "us-east-1"
                ],
                capture_output=True,
                text=True,
                check=True,
                env=env
            )
            
            topics = json.loads(result.stdout)
            
            # Buscar o tópico de pedidos processados
            topic_arn = None
            for topic in topics.get('Topics', []):
                if SNS_TOPIC_NAME in topic['TopicArn']:
                    topic_arn = topic['TopicArn']
                    break
            
            if not topic_arn:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'messages': [],
                    'topic': None,
                    'info': 'Tópico SNS não encontrado'
                }).encode())
                return
            
            # Buscar inscrições do tópico
            result = subprocess.run(
                [
                    "aws", "--endpoint-url", LOCALSTACK_ENDPOINT,
                    "sns", "list-subscriptions-by-topic",
                    "--topic-arn", topic_arn,
                    "--region", "us-east-1"
                ],
                capture_output=True,
                text=True,
                check=True,
                env=env
            )
            
            subscriptions_data = json.loads(result.stdout)
            subscriptions = subscriptions_data.get('Subscriptions', [])
            
            # Responder com informações do SNS
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response_data = {
                'topic': topic_arn,
                'subscriptions': len(subscriptions),
                'subscribers': [
                    {
                        'protocol': sub.get('Protocol'),
                        'endpoint': sub.get('Endpoint'),
                        'status': sub.get('SubscriptionArn', 'PendingConfirmation')
                    }
                    for sub in subscriptions
                ],
                'info': f'Tópico SNS configurado com {len(subscriptions)} inscrição(ões)'
            }
            
            self.wfile.write(json.dumps(response_data, indent=2).encode())
            
        except Exception as e:
            self.send_error(500, f"Erro ao buscar SNS: {str(e)}")
    
    def get_published_sns_messages(self):
        """Busca mensagens publicadas no SNS dos logs do Docker LocalStack."""
        try:
            # Buscar logs do container LocalStack
            result = subprocess.run(
                ["docker", "logs", "--tail", "200", "localstack"],
                capture_output=True,
                text=True,
                check=True
            )
            
            logs = result.stdout + result.stderr
            lines = logs.split('\n')
            
            # Filtrar mensagens SNS publicadas com sucesso
            messages = []
            
            for i, line in enumerate(lines):
                # Procurar por publicações SNS bem-sucedidas
                if 'AWS sns.Publish => 200' in line:
                    # Pegar timestamp da linha
                    timestamp = line.split()[0] if line.split() else 'unknown'
                    
                    # Procurar a mensagem nas próximas linhas
                    for j in range(i, min(i+20, len(lines))):
                        next_line = lines[j]
                        
                        # Procurar pela mensagem SNS com detalhes do pedido
                        if 'SnsMessage' in next_line and 'pedidoId' in next_line:
                            try:
                                # Extrair o JSON da mensagem
                                start = next_line.index('message=\'') + 9
                                end = next_line.index('\', message_attributes')
                                json_str = next_line[start:end].replace('\\"', '"')
                                
                                msg_data = json.loads(json_str)
                                
                                messages.append({
                                    'timestamp': timestamp,
                                    'type': 'success',
                                    'data': msg_data,
                                    'raw': f'SNS Publish Success - {timestamp}'
                                })
                                break
                            except Exception as e:
                                # Se não conseguir parsear, adiciona linha raw
                                messages.append({
                                    'timestamp': timestamp,
                                    'type': 'success',
                                    'data': None,
                                    'raw': next_line.strip()
                                })
                                break
            
            # Limitar a 30 mensagens mais recentes
            messages = messages[-30:]
            messages.reverse()  # Mais recentes primeiro
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response_data = {
                'messages': messages,
                'count': len(messages),
                'info': f'Últimas {len(messages)} publicações SNS bem-sucedidas (status 200)'
            }
            
            self.wfile.write(json.dumps(response_data, indent=2).encode())
            
        except subprocess.CalledProcessError as e:
            self.send_error(500, f"Erro ao buscar logs do Docker: {str(e)}")
        except Exception as e:
            self.send_error(500, f"Erro ao processar mensagens SNS: {str(e)}")
    
    def log_message(self, format, *args):
        """Log customizado."""
        if self.path.startswith('/api/'):
            print(f"🔄 {args[0]} - {args[1]}")
        elif self.path == '/sns/messages':
            print(f"📧 {args[0]} - {args[1]}")
        elif self.path == '/sns/published':
            print(f"📬 {args[0]} - {args[1]}")
        else:
            print(f"📄 {args[0]} - {args[1]}")


def main():
    """Inicia o servidor proxy."""
    print("🚀 Iniciando proxy server para API Gateway...")
    print()
    
    # Descobrir API ID
    api_id = get_api_id()
    if not api_id:
        print()
        print("⚠️  Não foi possível encontrar o API ID automaticamente.")
        print("   Execute o deploy do API Gateway primeiro:")
        print("   .\\infra\\localstack\\scripts\\deploy-apigateway.ps1")
        sys.exit(1)
    
    ProxyHandler.api_id = api_id
    
    # Iniciar servidor
    print()
    print(f"✅ Proxy configurado para API: {api_id}")
    print(f"🌐 Servidor rodando em: http://localhost:{PORT}")
    print()
    print("📍 Endpoints disponíveis:")
    print(f"   POST http://localhost:{PORT}/api/pedidos")
    print(f"   GET  http://localhost:{PORT}/api/pedidos")
    print(f"   GET  http://localhost:{PORT}/api/pedidos/{{id}}")
    print(f"   GET  http://localhost:{PORT}/sns/messages")
    print(f"   GET  http://localhost:{PORT}/sns/published")
    print()
    print("🎨 Frontend disponível em:")
    print(f"   http://localhost:{PORT}/index.html")
    print()
    print("Pressione Ctrl+C para parar o servidor")
    print("-" * 60)
    
    try:
        server = HTTPServer(('localhost', PORT), ProxyHandler)
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 Servidor encerrado")
        sys.exit(0)


if __name__ == '__main__':
    main()
