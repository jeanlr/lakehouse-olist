# Lakehouse Olist — Plataforma de Dados para Machine Learning

Plataforma de engenharia de dados end-to-end construída sobre o dataset público da Olist, implementando uma arquitetura **Lakehouse** completa — da ingestão bruta até a disponibilização de features prontas para Machine Learning e consumo analítico via BI. O projeto reproduz, em ambiente local containerizado, os padrões arquiteturais utilizados em ambientes corporativos de produção: separação em camadas (medallion architecture), orquestração declarativa, catálogo de metadados centralizado e desacoplamento entre armazenamento e processamento.

## Descrição do Projeto

Este repositório implementa um pipeline de dados completo que parte de arquivos CSV brutos do e-commerce Olist e os transforma, por meio de processamento distribuído com Apache Spark, em uma camada analítica (ABT — Analytical Base Table) pronta para treinamento de modelos de Machine Learning.

O projeto foi desenhado com foco em três pilares de engenharia de dados moderna:

- **Desacoplamento de armazenamento e computação**: o MinIO atua como Data Lake compatível com S3, enquanto o Spark realiza o processamento de forma independente e elástica.
- **Governança e catálogo único de dados**: o Hive Metastore centraliza o schema de todas as tabelas do Lakehouse, permitindo que múltiplos engines (Spark, Trino) leiam os mesmos dados de forma consistente.
- **Orquestração e reprodutibilidade**: todo o pipeline é versionado como código e orquestrado via Airflow, garantindo idempotência, rastreabilidade e agendamento confiável.

O resultado é uma plataforma onde um cientista de dados pode consumir features já tratadas via Jupyter, um analista de negócio pode explorar indicadores via Metabase/Trino, e um engenheiro de dados pode evoluir o pipeline com isolamento total entre as camadas.

## Arquitetura do Lakehouse

A arquitetura segue o padrão **Medallion (Landing → Bronze → Silver → Gold)**, amplamente adotado em plataformas Lakehouse modernas (Databricks, AWS Lake Formation, Azure Synapse). Cada camada possui um contrato de qualidade e um propósito bem definidos, evitando que dados brutos e dados de negócio se misturem.

Fluxo macro de dados:

Fontes CSV (Olist) → Landing (MinIO, raw) → Bronze (Spark, estrutura tabular) → Silver (Spark, limpeza e conformidade) → Gold / ABT (Spark, features de negócio) → Consumo (Jupyter / Trino / Metabase)

Integração entre os componentes:

- **Spark** é o motor de processamento distribuído responsável por ler, transformar e escrever dados entre as camadas do Lakehouse. Ele lê diretamente do MinIO via protocolo S3A e grava os resultados de volta no Data Lake em formato tabular.
- **MinIO** funciona como o Data Lake físico, armazenando os arquivos de cada camada (Landing, Bronze, Silver, Gold) em buckets segregados, emulando um storage de objetos S3 on-premise.
- **Hive Metastore** atua como catálogo técnico único: registra o schema, a localização física e o particionamento de cada tabela criada pelo Spark, permitindo que outros engines — como o Trino — consultem os mesmos dados sem reprocessamento.
- **Trino** é o motor de consulta distribuído utilizado para consumo analítico de baixa latência, lendo as tabelas registradas no Hive Metastore diretamente do MinIO, sem necessidade de mover ou duplicar dados.
- **Airflow** orquestra a execução de todo o pipeline (ingestão, transformação entre camadas, treino de modelos), garantindo agendamento, retries e observabilidade das execuções via DAGs versionadas em código.
- **Jupyter** é o ambiente de experimentação utilizado por engenheiros de ML para explorar a camada Gold, validar features e treinar modelos antes de promovê-los a produção.
- **Metabase** consome os dados via Trino para construção de dashboards e relatórios de negócio, oferecendo uma camada de BI self-service sobre o Lakehouse.
- **PostgreSQL** desempenha papel duplo: metastore de suporte a serviços (Airflow) e base OLTP de referência para dados transacionais do Olist e do Metabase.

Esta separação garante que mudanças na camada de processamento (Spark) não impactem o consumo (Trino/Metabase), e que o catálogo (Hive Metastore) seja a única fonte de verdade sobre a estrutura dos dados.

## Stack Tecnológica

| Componente | Função na Arquitetura |
|---|---|
| Apache Spark | Processamento distribuído e transformação de dados entre camadas do Lakehouse |
| MinIO | Object Storage compatível com S3, base física do Data Lake |
| Hive Metastore | Catálogo de metadados centralizado (schemas, tabelas, partições) |
| Trino | Query engine distribuído para consultas analíticas federadas sobre o Lakehouse |
| Apache Airflow | Orquestração, agendamento e monitoramento de pipelines (DAGs) |
| PostgreSQL | Banco OLTP e metastore de suporte (Airflow, Olist, Metabase) |
| Jupyter Notebook | Ambiente de experimentação, EDA e desenvolvimento de modelos de ML |
| Metabase | Camada de BI e visualização de dados self-service |
| Docker Compose | Orquestração e provisionamento do ambiente local multi-serviço |

## Pré-requisitos

Antes de iniciar, garanta que o ambiente local possui:

- Docker Engine 24+ e Docker Compose v2
- Mínimo de 8 GB de RAM disponíveis para os containers (recomendado 16 GB)
- Mínimo de 10 GB de espaço livre em disco para volumes e datasets
- Portas locais listadas na seção de serviços livres (sem conflito com outros serviços já em execução)
- Sistema operacional Linux, macOS ou Windows com WSL2

## Instalação e Configuração

1. Clone o repositório e acesse o diretório raiz do projeto.
2. Garanta que o dataset Olist (arquivos CSV) está presente no diretório `src/data/`. Caso não esteja, baixe o dataset público da Olist e posicione os arquivos neste caminho antes de subir o pipeline.
3. Verifique o diretório `drivers/`, que deve conter o driver JDBC `postgresql.jar`, utilizado pelo Spark para conexões com o PostgreSQL.
4. Revise o diretório `config/`, onde ficam centralizadas variáveis de ambiente e configurações compartilhadas entre os serviços (credenciais do MinIO, conexões do Airflow, parâmetros do Hive Metastore, entre outros).
5. Caso seja necessário customizar credenciais (usuários e senhas do PostgreSQL, MinIO, Airflow), ajuste as variáveis de ambiente referenciadas no `docker-compose.yml` antes da primeira inicialização.

## Como Subir o Ambiente

O ambiente completo é provisionado via Docker Compose, a partir da raiz do projeto:

1. Construa as imagens customizadas (Airflow com dependências adicionais, por exemplo) e suba todos os serviços em segundo plano: `docker-compose up -d --build`.
2. Acompanhe os logs durante a inicialização, especialmente do serviço de inicialização do Airflow (`airflow-init`), que cria o banco de metadados e o usuário administrador antes que o Webserver e o Scheduler fiquem disponíveis: `docker-compose logs -f airflow-init`.
3. Aguarde todos os serviços reportarem status saudável (`healthy`) com `docker-compose ps`.
4. Acesse as interfaces web listadas na tabela de serviços abaixo para validar que cada componente subiu corretamente.
5. Para encerrar o ambiente preservando os volumes (dados persistidos), utilize `docker-compose down`. Para um reset completo, incluindo dados do MinIO, PostgreSQL e Hive, utilize `docker-compose down -v`.

A ordem de dependência entre os serviços é respeitada automaticamente pelo Compose: o PostgreSQL e o MinIO sobem primeiro, seguidos pelo Hive Metastore (que depende do PostgreSQL como backend de metadados), depois o Spark Master/Workers, o Airflow (Webserver, Scheduler e o job de inicialização), o Trino (que depende do Hive Metastore para descoberta de schema) e, por fim, o Jupyter e o Metabase.

## Serviços e Acessos

| Serviço | Descrição | Porta Local | Credenciais Padrão |
|---|---|---|---|
| MinIO Console | Interface web do Data Lake (S3-compatible) | 9001 | minioadmin / minioadmin |
| MinIO API | Endpoint S3 utilizado por Spark e Trino | 9000 | minioadmin / minioadmin |
| Spark Master UI | Monitoramento do cluster Spark | 8080 | — |
| Spark Worker UI | Monitoramento de workers individuais | 8081 | — |
| Airflow Webserver | Interface de orquestração de DAGs | 8082 | airflow / airflow |
| Jupyter Notebook | Ambiente de análise e ML | 8888 | Token exibido no log do container |
| Hive Metastore | Catálogo de metadados (Thrift) | 9083 | — |
| Trino | Query engine distribuído | 8084 | — |
| Metabase | Plataforma de BI | 3000 | Configurado no primeiro acesso |
| PostgreSQL | Banco OLTP / metastore | 5432 | postgres / postgres |

As portas indicadas refletem o mapeamento padrão configurado no `docker-compose.yml`; ajuste conforme necessário caso haja conflito com serviços já em execução na máquina host.

## Estrutura do Projeto

- `airflow/` — Orquestração de pipelines. Contém o `Dockerfile` da imagem customizada do Airflow, o diretório `dags/` com a definição do pipeline (`pipeline_eng.py`), `plugins/` para extensões customizadas e `logs/` para execução das tasks.
- `config/` — Arquivos de configuração e variáveis de ambiente compartilhadas entre os serviços do Compose.
- `docker-compose.yml` — Definição declarativa de todo o ambiente multi-serviço (MinIO, Spark, Airflow, Hive, Trino, Metabase, PostgreSQL).
- `drivers/` — Drivers JDBC necessários para integração entre Spark e bancos relacionais (`postgresql.jar`).
- `hive/` — Configurações específicas do Hive Metastore.
- `jupyter/` — Configurações e dependências do ambiente Jupyter.
- `scripts/` — Núcleo de lógica de ETL e Machine Learning: notebooks de transformação e treino, módulo utilitário `util.py` com funções reutilizáveis de leitura/escrita no Lakehouse, e artefatos de modelos serializados (`.pkl`).
- `spark/` — Configurações do cluster Spark (Master e Workers).
- `src/data/` — Datasets brutos da Olist em formato CSV, ponto de entrada da camada Landing.
- `trino/` — Configurações de catálogo e conectores do Trino.
- `README.md` — Documentação do projeto.

## Pipeline de Dados (End-to-End)

O pipeline é definido como uma DAG declarativa em `airflow/dags/pipeline_eng.py` e segue o seguinte fluxo:

1. **Ingestão (Landing)**: os arquivos CSV em `src/data/` são carregados sem transformação para o bucket de Landing no MinIO, preservando o dado em seu formato original como cópia fiel da fonte.
2. **Padronização (Bronze)**: jobs Spark leem os arquivos da Landing, aplicam tipagem de schema e convertem os dados para formato tabular otimizado, gravando o resultado no bucket Bronze e registrando as tabelas no Hive Metastore.
3. **Limpeza e Conformidade (Silver)**: novos jobs Spark aplicam regras de qualidade — deduplicação, tratamento de nulos, normalização de chaves e tipos, padronização de domínios — produzindo tabelas Silver íntegras e auditáveis.
4. **Construção da Camada Analítica (Gold/ABT)**: as tabelas Silver são unidas (joins) e agregadas em uma Analytical Base Table orientada ao problema de negócio (por exemplo, previsão de atraso de entrega ou satisfação do cliente), com engenharia de features aplicada diretamente em Spark.
5. **Disponibilização**: a camada Gold fica acessível simultaneamente via Spark (para notebooks de ML no Jupyter) e via Trino (para consultas analíticas e BI no Metabase), sem necessidade de duplicação de dados.
6. **Treino e Persistência de Modelo**: notebooks em `scripts/` consomem a ABT, treinam modelos de Machine Learning e persistem os artefatos resultantes (`.pkl`) para reuso posterior.

Cada etapa é idempotente e particionada por execução, permitindo reprocessamento seguro em caso de falha em qualquer estágio do pipeline.

## Camadas do Lakehouse

| Camada | Propósito | Formato | Transformações Aplicadas |
|---|---|---|---|
| Landing | Cópia fiel da fonte, sem alterações | CSV bruto | Nenhuma — apenas ingestão |
| Bronze | Dados estruturados e tipados | Tabular (Spark) | Parsing, tipagem de schema, registro no catálogo |
| Silver | Dados limpos e confiáveis | Tabular (Spark) | Deduplicação, tratamento de nulos, normalização, joins de integridade |
| Gold (ABT) | Dados prontos para consumo analítico e ML | Tabular (Spark) | Agregações de negócio, engenharia de features, granularidade orientada ao modelo |

Esta segregação garante rastreabilidade completa: é sempre possível auditar de qual registro Bronze uma feature da camada Gold se originou, e reprocessar uma camada isoladamente sem impactar as demais.

## Fluxo de Machine Learning

O fluxo de ML é construído inteiramente sobre a camada Gold do Lakehouse, garantindo que features de treino e features de produção sempre tenham a mesma origem e lógica de cálculo:

1. **Feature Engineering**: realizado em Spark durante a construção da camada Gold, garantindo escalabilidade e consistência entre execuções (evita o problema clássico de train/serving skew).
2. **Exploração e Validação**: notebooks no Jupyter consomem a ABT diretamente do Lakehouse (via Spark ou Trino) para análise exploratória, validação estatística das features e seleção de variáveis.
3. **Treinamento**: os modelos são treinados nos notebooks de ML em `scripts/`, com experimentação iterativa sobre os dados da camada Gold.
4. **Persistência**: o modelo treinado é serializado em formato `.pkl` e armazenado em `scripts/`, junto a metadados relevantes do experimento (features utilizadas, métricas de avaliação).
5. **Reuso**: os artefatos `.pkl` podem ser carregados por novos notebooks ou por jobs futuros do Airflow para inferência em lote, fechando o ciclo entre engenharia de dados e ciência de dados.

## Artefatos Gerados

O diretório `scripts/` concentra os artefatos produzidos durante o ciclo de Machine Learning:

- **Modelos serializados (`.pkl`)**: representações binárias dos modelos treinados, prontas para carregamento e inferência sem necessidade de retraino.
- **Notebooks de ETL**: documentam e implementam de forma exploratória as transformações entre as camadas Bronze, Silver e Gold antes de sua consolidação na DAG de produção.
- **Notebooks de ML**: contêm o processo de feature selection, treinamento, validação cruzada e avaliação de métricas dos modelos.
- **`util.py`**: módulo utilitário compartilhado entre notebooks, centralizando funções reutilizáveis de leitura/escrita no MinIO, conexão com Spark e funções auxiliares de pré-processamento — evitando duplicação de lógica entre notebooks.

Centralizar artefatos e lógica reutilizável neste diretório reduz acoplamento entre notebooks individuais e facilita a futura migração de lógica validada para jobs produtivos no Airflow.

## Monitoramento e Orquestração (Airflow)

O Airflow é o componente responsável pela confiabilidade operacional do pipeline:

- A DAG principal (`pipeline_eng.py`) define explicitamente as dependências entre as etapas Landing → Bronze → Silver → Gold, garantindo que uma camada só seja processada após a conclusão bem-sucedida da anterior.
- Cada task é independente e idempotente, podendo ser reexecutada isoladamente em caso de falha, sem necessidade de reprocessar o pipeline inteiro.
- A interface web do Airflow (porta 8082) oferece visibilidade completa sobre o histórico de execuções, duração de cada task, logs detalhados e alertas de falha.
- O `airflow-init`, executado uma única vez na subida do ambiente, prepara o banco de metadados do Airflow no PostgreSQL e cria o usuário administrador inicial.
- O versionamento da DAG como código (Python) garante que toda mudança no pipeline seja rastreável via controle de versão, alinhado às práticas de Data Engineering as Code.

## BI e Consumo de Dados (Trino + Metabase)

A camada de consumo analítico é desacoplada do processamento, permitindo consultas de baixa latência diretamente sobre o Lakehouse:

- O **Trino** se conecta ao Hive Metastore para descobrir o schema das tabelas Gold e executa consultas distribuídas diretamente sobre os arquivos armazenados no MinIO, sem necessidade de ETL adicional ou cópia de dados para um data warehouse separado.
- O **Metabase** utiliza o Trino como fonte de dados, permitindo que analistas de negócio construam dashboards e explorem métricas da camada Gold por meio de uma interface self-service, sem necessidade de escrever SQL complexo ou ter acesso direto ao cluster Spark.
- Esta arquitetura elimina a necessidade de um data warehouse tradicional: o próprio Lakehouse, através de Trino, desempenha o papel de camada de serving analítico (padrão conhecido como "Lakehouse as the single source of truth").

## Contribuição

Contribuições são bem-vindas e devem seguir as práticas abaixo:

1. Crie uma branch a partir da `main` com um nome descritivo da mudança proposta (ex.: `feature/nova-feature-gold`, `fix/ajuste-dag-airflow`).
2. Mantenha a separação de responsabilidades entre as camadas do Lakehouse — alterações na lógica de negócio devem ocorrer na camada Silver/Gold, nunca na Bronze ou Landing.
3. Toda nova transformação de dados deve ser adicionada como uma task isolada e idempotente na DAG do Airflow, evitando lógica acoplada diretamente em notebooks de produção.
4. Documente novas variáveis de ambiente ou dependências no `config/` correspondente.
5. Abra um Pull Request descrevendo o problema resolvido, o impacto nas camadas do Lakehouse e, quando aplicável, evidências de teste local com `docker-compose up`.

## Licença

Este projeto é distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para o texto completo dos termos de uso, modificação e distribuição.