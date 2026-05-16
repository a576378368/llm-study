# 第二部分：Agent与工具使用

> Agent是大模型发展的重要方向，能够自主规划、执行复杂任务。本章介绍Agent基础、现有系统、工具使用和应用场景。

## 2.1 Agent基础

### 2.1.1 Agent概念

Agent（智能体）是能够感知环境、做出决策并执行行动的自主系统。

**Agent的核心组件**：

```
Agent
├── 感知模块 (Perception)
├── 规划模块 (Planning)
├── 记忆模块 (Memory)
├── 工具使用 (Tools)
└── 执行模块 (Action)
```

**与大语言模型的区别**：

| 特性 | 大语言模型 | Agent |
|------|------------|-------|
| 能力 | 文本生成 | 规划+执行 |
| 交互 | 被动响应 | 主动行动 |
| 工具使用 | 无 | 有 |
| 目标导向 | 无 | 有 |
| 自主性 | 低 | 高 |

### 2.1.2 感知-决策-行动循环

Agent通过感知-决策-行动循环与环境交互。

**循环流程**：

```python
class Agent:
    """Agent基类"""
    def __init__(self):
        self.perception = PerceptionModule()
        self.planning = PlanningModule()
        self.memory = MemoryModule()
        self.tools = ToolRegistry()
        self.action = ActionModule()

    def run(self, observation):
        """Agent主循环"""
        # 1. 感知：理解当前状态
        state = self.perception.process(observation)

        # 2. 决策：规划下一步行动
        plan = self.planning.create_plan(state, self.memory)

        # 3. 执行：执行行动
        result = self.action.execute(plan, self.tools)

        # 4. 更新记忆
        self.memory.add_experience(state, plan, result)

        return result

class PerceptionModule:
    """感知模块"""
    def process(self, observation):
        """
        处理观察输入
        observation: 原始观察（文本、图像、传感器数据等）
        """
        if isinstance(observation, str):
            return {"type": "text", "content": observation}
        elif isinstance(observation, dict):
            return observation
        else:
            return {"type": "unknown", "raw": observation}

class PlanningModule:
    """规划模块"""
    def create_plan(self, state, memory):
        """创建行动计划"""
        # 检索相关记忆
        relevant_history = memory.retrieve(state)

        # 分解任务
        goals = self.decompose_task(state['goal'])

        # 选择行动序列
        plan = []
        for goal in goals:
            action = self.select_action(goal, relevant_history)
            plan.append(action)

        return plan

    def decompose_task(self, task):
        """任务分解"""
        # 使用LLM分解复杂任务
        prompt = f"""将以下任务分解为可执行的步骤：

        任务：{task}

        步骤（每个步骤描述一个具体的行动）："""

        response = self.llm.generate(prompt)
        steps = self.parse_steps(response)

        return steps

class MemoryModule:
    """记忆模块"""
    def __init__(self):
        self.short_term = []  # 近期经验
        self.long_term = []    # 长期记忆

    def add_experience(self, state, plan, result):
        """添加经验"""
        self.short_term.append({
            'state': state,
            'plan': plan,
            'result': result,
            'timestamp': time.time()
        })

        # 定期将重要经验转入长期记忆
        if len(self.short_term) > 10:
            self.consolidate()

    def retrieve(self, current_state, k=5):
        """检索相关记忆"""
        # 基于相似度检索
        scores = []
        for exp in self.short_term + self.long_term:
            score = self.similarity(current_state, exp['state'])
            scores.append(score)

        top_k_indices = sorted(range(len(scores)), key=lambda i: scores[i])[-k:]
        return [self.short_term[i] if i < len(self.short_term)
                else self.long_term[i - len(self.short_term)]
                for i in top_k_indices]
```

### 2.1.3 工具使用机制

工具使用扩展了Agent的能力边界。

**工具定义与注册**：

```python
from typing import Callable, Dict, Any
from dataclasses import dataclass

@dataclass
class Tool:
    """工具定义"""
    name: str
    description: str
    parameters: Dict[str, Any]
    function: Callable

class ToolRegistry:
    """工具注册表"""
    def __init__(self):
        self.tools = {}

    def register(self, name: str, description: str, parameters: Dict, func: Callable):
        """注册工具"""
        self.tools[name] = {
            'description': description,
            'parameters': parameters,
            'function': func
        }

    def get_tool(self, name: str) -> Tool:
        """获取工具"""
        return self.tools.get(name)

    def list_tools(self) -> list:
        """列出所有工具"""
        return [
            {'name': name, 'description': tool['description']}
            for name, tool in self.tools.items()
        ]

    def execute(self, name: str, **kwargs) -> Any:
        """执行工具"""
        if name not in self.tools:
            raise ValueError(f"Unknown tool: {name}")

        tool = self.tools[name]

        # 参数验证
        self._validate_params(tool['parameters'], kwargs)

        # 执行
        return tool['function'](**kwargs)

# 示例：注册搜索工具
def search_web(query: str, num_results: int = 5) -> str:
    """搜索网络"""
    # 实际实现中调用搜索引擎API
    results = google_search(query, num_results)
    return format_results(results)

tool_registry = ToolRegistry()
tool_registry.register(
    name="web_search",
    description="搜索网络获取信息",
    parameters={"query": "str", "num_results": "int"},
    func=search_web
)
```

**工具选择与调用**：

```python
class ToolCallingAgent:
    """工具调用Agent"""
    def __init__(self, llm, tool_registry):
        self.llm = llm
        self.tools = tool_registry

    def generate_response(self, user_message):
        """生成响应（可能包含工具调用）"""
        # 构建提示
        prompt = self._build_prompt(user_message)

        # 调用LLM
        response = self.llm.generate(prompt)

        # 解析工具调用
        if self._contains_tool_call(response):
            tool_calls = self._parse_tool_calls(response)
            return self._execute_tool_calls(tool_calls)

        return response

    def _build_prompt(self, user_message):
        """构建提示"""
        available_tools = self.tools.list_tools()

        prompt = f"""你是一个助手，可以使用工具来完成任务。

可用工具：
{self._format_tools(available_tools)}

用户消息：{user_message}

请你决定是否需要调用工具。如果需要，请按以下格式输出：

动作：工具名称
参数：{{"参数名": "参数值"}}

如果不需要工具，直接回答。"""

        return prompt

    def _execute_tool_calls(self, tool_calls):
        """执行工具调用"""
        results = []
        for tool_call in tool_calls:
            tool_name = tool_call['name']
            tool_args = tool_call['arguments']

            try:
                result = self.tools.execute(tool_name, **tool_args)
                results.append({'tool': tool_name, 'result': result})
            except Exception as e:
                results.append({'tool': tool_name, 'error': str(e)})

        return self._format_results(results)
```

---

## 2.2 现有Agent系统

### 2.2.1 AutoGPT

AutoGPT是自主Agent的代表，可以分解复杂任务并执行。

**AutoGPT核心机制**：

```python
class AutoGPTAgent:
    """AutoGPT风格的Agent"""
    def __init__(self, llm, tools):
        self.llm = llm
        self.tools = tools
        self.objective = None
        self.task_list = []

    def set_objective(self, objective):
        """设置目标"""
        self.objective = objective
        self.task_list = [Task(objective)]

    def run(self, max_iterations=50):
        """运行Agent"""
        for iteration in range(max_iterations):
            print(f"\n=== 迭代 {iteration + 1} ===")
            print(f"当前目标: {self.objective}")

            # 获取下一个任务
            if not self.task_list:
                break

            current_task = self.task_list.pop(0)
            print(f"执行任务: {current_task.description}")

            # 执行任务
            result = self._execute_task(current_task)

            # 分析结果
            analysis = self._analyze_result(result)

            # 生成新任务
            new_tasks = self._generate_subtasks(analysis)

            # 添加新任务
            for task in new_tasks:
                self.task_list.append(task)

            print(f"结果: {result[:200]}...")
            print(f"新增任务数: {len(new_tasks)}")

            # 检查是否完成
            if self._is_objective_complete():
                print("目标已完成！")
                break

    def _execute_task(self, task):
        """执行单个任务"""
        prompt = f"""你是一个自主AI助手，需要完成以下任务：

任务：{task.description}

可用工具：
{self._format_tools()}

请决定使用哪个工具（如果有），并执行任务。

执行过程："""

        response = self.llm.generate(prompt)

        # 如果需要工具，调用工具
        if self._needs_tool(response):
            tool_calls = self._extract_tool_calls(response)
            return self._execute_tools(tool_calls)

        return response

class Task:
    """任务类"""
    def __init__(self, description, status="pending", result=None):
        self.description = description
        self.status = status
        self.result = result

    def __repr__(self):
        return f"Task({self.description[:50]}..., status={self.status})"
```

### 2.2.2 BabyAGI

BabyAGI是基于目标管理的Agent系统。

```python
class BabyAGI:
    """BabyAGI Agent"""
    def __init__(self, objective, task_generator, execution_agent, storage):
        self.objective = objective
        self.task_generator = task_generator
        self.execution_agent = execution_agent
        self.storage = storage  # 存储已完成任务结果

        self.task_list = []

    def run(self, max_iterations=5):
        """运行BabyAGI"""
        # 初始化：从目标创建第一个任务
        first_task = Task(
            description=f"执行任务以实现目标：{self.objective}"
        )
        self.task_list.append(first_task)

        for iteration in range(max_iterations):
            print(f"\n=== 迭代 {iteration + 1} ===")

            # 1. 从任务列表中提取任务
            if not self.task_list:
                print("没有更多任务，完成！")
                break

            task = self.task_list.pop(0)
            print(f"处理任务: {task.description}")

            # 2. 执行任务
            result = self.execution_agent.execute(task.description)

            print(f"执行结果: {result[:100]}...")

            # 3. 存储结果
            self.storage.append({
                'task': task.description,
                'result': result
            })

            # 4. 生成新任务
            new_tasks = self.task_generator.generate(
                objective=self.objective,
                completed_task=task.description,
                result=result,
                previous_tasks=self.storage
            )

            # 5. 添加新任务到列表
            for new_task in new_tasks:
                if new_task not in self.task_list:
                    self.task_list.append(new_task)

            print(f"新增任务数: {len(new_tasks)}, 待处理: {len(self.task_list)}")

        print("\n=== 最终结果 ===")
        return self.storage

class TaskGenerator:
    """任务生成器"""
    def __init__(self, llm):
        self.llm = llm

    def generate(self, objective, completed_task, result, previous_tasks):
        """基于结果生成新任务"""
        prompt = f"""给定以下信息，生成可能的后续任务：

目标：{objective}
刚完成的任务：{completed_task}
任务结果：{result}

请列出3-5个具体的后续任务，以便进一步推进目标。

每个任务应该：
- 明确且可执行
- 推进目标进展
- 可以是研究、执行或验证任务

任务列表："""

        response = self.llm.generate(prompt)
        tasks = self._parse_tasks(response)

        return [Task(desc) for desc in tasks]
```

### 2.2.3 LangChain Agents

LangChain提供了丰富的Agent框架。

```python
from langchain.agents import AgentExecutor, Tool, ZeroShotAgent
from langchain.prompts import PromptTemplate
from langchain.memory import ConversationBufferMemory

class LangChainAgent:
    """LangChain Agent实现"""
    def __init__(self, llm, tools):
        self.llm = llm
        self.tools = self._create_tools(tools)
        self.memory = ConversationBufferMemory(memory_key="chat_history")

    def _create_tools(self, tool_defs):
        """创建LangChain工具"""
        tools = []
        for tool_def in tool_defs:
            tools.append(Tool(
                name=tool_def['name'],
                func=tool_def['func'],
                description=tool_def['description']
            ))
        return tools

    def create_agent(self):
        """创建Agent"""
        prompt = PromptTemplate(
            template="""你是一个有帮助的助手。

当前对话历史：
{chat_history}

可用工具：
{tool_names}

工具描述：
{tools}

问题：{input}

思考过程：
{agent_scratchpad}

回答：""",
            input_variables=["input", "chat_history", "agent_scratchpad"],
            partial_variables={"tools": self._format_tools(), "tool_names": self._get_tool_names()}
        )

        agent = ZeroShotAgent(
            llm=self.llm,
            prompt=prompt,
            tools=self.tools,
            verbose=True
        )

        return AgentExecutor.from_agent_and_tools(
            agent=agent,
            tools=self.tools,
            memory=self.memory,
            max_iterations=10
        )

    def run(self, query):
        """运行Agent"""
        agent_executor = self.create_agent()
        result = agent_executor.run(query)
        return result

# 使用示例
llm = OpenAI(temperature=0)
tools = [
    {
        'name': 'search',
        'func': search_web,
        'description': '用于搜索网络获取信息'
    },
    {
        'name': 'calculator',
        'func': calculate,
        'description': '用于数学计算'
    }
]

agent = LangChainAgent(llm, tools)
result = agent.run("帮我查一下今天北京的天气，然后计算一下如果我开车去需要多少油费")
```

### 2.2.4 其他框架

**Hugging Face Agent**：

```python
from transformers import Agent

# 定义工具
def search(query):
    """搜索工具"""
    return f"搜索结果: {query}的相关信息..."

def calculator(expression):
    """计算器"""
    return f"计算结果: {eval(expression)}"

# 创建Agent
agent = Agent(
    tools=[search, calculator],
    llm="bigcode/starcoder",
    verbose=True
)

# 运行
result = agent.run("搜索一下Python的历史，然后计算2的10次方")
```

**Microsoft AutoGen**：

```python
import autogen

# 定义助手
assistant = autogen.AssistantAgent(
    name="assistant",
    llm_config={"model": "gpt-4"}
)

# 定义用户代理
user_proxy = autogen.UserProxyAgent(
    name="user",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10
)

# 启动对话
user_proxy.initiate_chat(
    assistant,
    message="帮我写一个快速排序算法"
)
```

---

## 2.3 工具使用方法

### 2.3.1 工具定义

工具定义需要清晰描述功能和使用方式。

**工具定义规范**：

```python
@dataclass
class ToolDefinition:
    """工具定义"""
    name: str                    # 工具名称
    description: str              # 功能描述（用于Agent理解）
    input_schema: Dict            # 输入参数模式（JSON Schema）
    output_schema: Dict           # 输出结果模式
    examples: List[Dict]          # 使用示例

    def to_openai_format(self):
        """转换为OpenAI工具格式"""
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": self.input_schema
            }
        }

class ToolFactory:
    """工具工厂"""
    @staticmethod
    def create_search_tool() -> ToolDefinition:
        return ToolDefinition(
            name="web_search",
            description="搜索网络获取信息。适用于需要实时数据、新闻或不明信息时使用。",
            input_schema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "搜索查询字符串"
                    },
                    "num_results": {
                        "type": "integer",
                        "description": "返回结果数量",
                        "default": 5
                    }
                },
                "required": ["query"]
            },
            output_schema={
                "type": "object",
                "properties": {
                    "results": {
                        "type": "array",
                        "items": {"type": "string"}
                    }
                }
            },
            examples=[
                {"input": {"query": "Python教程"}, "output": {"results": ["结果1", "结果2"]}}
            ]
        )
```

### 2.3.2 工具调用

工具调用需要处理执行和结果返回。

```python
class ToolExecutor:
    """工具调用执行器"""
    def __init__(self, tool_registry):
        self.registry = tool_registry
        self.execution_history = []

    def execute(self, tool_call: Dict) -> Dict:
        """
        执行工具调用
        tool_call: {"name": "tool_name", "arguments": {...}}
        """
        tool_name = tool_call['name']
        arguments = tool_call.get('arguments', {})

        try:
            result = self.registry.execute(tool_name, **arguments)

            # 记录执行历史
            self.execution_history.append({
                'tool': tool_name,
                'arguments': arguments,
                'result': result,
                'status': 'success'
            })

            return {
                'status': 'success',
                'result': result
            }

        except Exception as e:
            self.execution_history.append({
                'tool': tool_name,
                'arguments': arguments,
                'error': str(e),
                'status': 'error'
            })

            return {
                'status': 'error',
                'error': str(e)
            }

    def execute_batch(self, tool_calls: List[Dict]) -> List[Dict]:
        """批量执行工具调用"""
        results = []
        for tool_call in tool_calls:
            result = self.execute(tool_call)
            results.append(result)

        return results

class ToolCallParser:
    """工具调用解析器"""
    def __init__(self, llm):
        self.llm = llm

    def parse(self, text_response: str) -> List[Dict]:
        """从文本响应中解析工具调用"""
        import json
        import re

        # 尝试从文本中提取工具调用
        # 格式：动作：工具名\n参数：{...}

        tool_calls = []

        # 正则匹配
        pattern = r'动作[：:]\s*(\w+)\s*参数[：:]\s*(\{[^}]+\})'
        matches = re.findall(pattern, text_response, re.MULTILINE)

        for tool_name, args_str in matches:
            try:
                args = json.loads(args_str)
                tool_calls.append({
                    'name': tool_name,
                    'arguments': args
                })
            except json.JSONDecodeError:
                continue

        return tool_calls
```

### 2.3.3 工具评估

工具评估确保工具的质量和可靠性。

```python
class ToolEvaluator:
    """工具评估器"""
    def __init__(self, executor):
        self.executor = executor

    def evaluate_tool(self, tool_def: ToolDefinition, test_cases: List[Dict]) -> Dict:
        """评估单个工具"""
        results = {
            'tool_name': tool_def.name,
            'total_tests': len(test_cases),
            'passed': 0,
            'failed': 0,
            'errors': []
        }

        for test_case in test_cases:
            tool_call = {
                'name': tool_def.name,
                'arguments': test_case['input']
            }

            result = self.executor.execute(tool_call)

            if result['status'] == 'success':
                # 验证输出
                if self._verify_output(result['result'], test_case['expected']):
                    results['passed'] += 1
                else:
                    results['failed'] += 1
                    results['errors'].append({
                        'input': test_case['input'],
                        'expected': test_case['expected'],
                        'actual': result.get('result')
                    })
            else:
                results['failed'] += 1
                results['errors'].append({
                    'input': test_case['input'],
                    'error': result.get('error')
                })

        results['pass_rate'] = results['passed'] / results['total_tests']
        return results

    def _verify_output(self, actual, expected):
        """验证输出是否符合预期"""
        if isinstance(expected, dict):
            for key, value in expected.items():
                if actual.get(key) != value:
                    return False
        return True

    def evaluate_all_tools(self, tool_definitions: List[ToolDefinition], test_cases: Dict) -> List[Dict]:
        """评估所有工具"""
        results = []
        for tool_def in tool_definitions:
            tool_tests = test_cases.get(tool_def.name, [])
            result = self.evaluate_tool(tool_def, tool_tests)
            results.append(result)
        return results
```

---

## 2.4 Agent应用场景

### 2.4.1 自动化任务

Agent可以自动完成复杂的多步骤任务。

```python
class TaskAutomationAgent:
    """任务自动化Agent"""
    def __init__(self, llm, tools):
        self.llm = llm
        self.tools = tools

    def automate_workflow(self, workflow_description: str, initial_input: Dict):
        """自动化工作流程"""
        # 解析工作流程
        steps = self._parse_workflow(workflow_description)

        # 执行每一步
        context = initial_input.copy()
        for step in steps:
            print(f"执行步骤: {step['name']}")

            # 确定需要的工具
            tool_name = self._select_tool(step, context)

            # 准备参数
            params = self._prepare_params(step, context)

            # 执行
            result = self.tools.execute(tool_name, **params)

            # 更新上下文
            context[step['name']] = result
            context['last_result'] = result

        return context

    def _parse_workflow(self, description):
        """解析工作流程描述"""
        prompt = f"""分析以下工作流程，分解为具体步骤：

工作流程：{description}

请列出步骤顺序，每个步骤包含：
- 名称
- 目的
- 所需输入

输出为JSON格式："""

        response = self.llm.generate(prompt)
        return json.loads(response)['steps']
```

### 2.4.2 复杂问题求解

Agent可以分解和解决复杂问题。

```python
class ProblemSolvingAgent:
    """问题求解Agent"""
    def __init__(self, llm):
        self.llm = llm

    def solve(self, problem: str) -> Dict:
        """解决复杂问题"""
        # 问题分析
        analysis = self.analyze_problem(problem)

        if analysis['type'] == 'simple':
            return self.solve_simple(analysis)
        else:
            return self.solve_complex(analysis)

    def analyze_problem(self, problem: str) -> Dict:
        """分析问题类型和难度"""
        prompt = f"""分析以下问题：

{problem}

请确定：
1. 问题类型（事实查询/计算/推理/创意）
2. 问题复杂度（简单/中等/复杂）
3. 需要的步骤
4. 潜在难点

JSON格式输出："""

        response = self.llm.generate(prompt)
        return json.loads(response)

    def solve_complex(self, analysis: Dict) -> Dict:
        """解决复杂问题"""
        solution_steps = []

        for step in analysis['steps']:
            print(f"处理步骤: {step}")

            # 子问题求解
            sub_result = self._solve_subproblem(step)
            solution_steps.append(sub_result)

        # 综合结果
        final_result = self._synthesize(solution_steps, analysis)

        return {
            'analysis': analysis,
            'steps': solution_steps,
            'result': final_result
        }
```

### 2.4.3 智能代理系统

智能代理系统协调多个Agent协作。

```python
class MultiAgentSystem:
    """多Agent系统"""
    def __init__(self):
        self.agents = {}
        self.coordinator = self._create_coordinator()

    def register_agent(self, name: str, agent):
        """注册Agent"""
        self.agents[name] = agent

    def _create_coordinator(self):
        """创建协调器"""
        return CoordinatorAgent(llm=OpenAI())

    def solve_complex_task(self, task: str) -> Dict:
        """解决复杂任务"""
        # 任务分解
        subtasks = self.coordinator.decompose(task)

        results = {}
        for subtask in subtasks:
            # 选择合适的Agent
            agent_name = self.coordinator.select_agent(subtask, self.agents)
            agent = self.agents[agent_name]

            # 执行子任务
            result = agent.execute(subtask)
            results[agent_name] = result

        # 综合结果
        final_result = self.coordinator.synthesize(results)

        return {
            'subtasks': subtasks,
            'results': results,
            'final': final_result
        }

class CoordinatorAgent:
    """协调Agent"""
    def __init__(self, llm):
        self.llm = llm

    def decompose(self, task: str) -> List[str]:
        """分解任务"""
        prompt = f"""将以下复杂任务分解为可并行的子任务：

任务：{task}

子任务应该：
- 相互独立（可以并行执行）
- 明确且可执行
- 足够细粒度以便分配给不同Agent

输出子任务列表，每行一个："""

        response = self.llm.generate(prompt)
        return [line.strip() for line in response.split('\n') if line.strip()]

    def select_agent(self, subtask: str, agents: Dict) -> str:
        """选择合适的Agent"""
        agent_descriptions = '\n'.join([
            f"- {name}: {agent.description}"
            for name, agent in agents.items()
        ])

        prompt = f"""对于以下子任务，选择最合适的Agent：

子任务：{subtask}

可用Agent：
{agent_descriptions}

Agent名称："""

        response = self.llm.generate(prompt).strip()
        return response if response in agents else list(agents.keys())[0]
```

---

## 本章小结

本章介绍了Agent与工具使用的核心内容：

1. **Agent基础**：
   - Agent是能够感知、决策、执行的自主系统
   - 感知-决策-行动循环是核心机制
   - 工具使用扩展了Agent的能力

2. **现有Agent系统**：
   - AutoGPT：自主任务分解和执行
   - BabyAGI：基于目标管理的Agent
   - LangChain Agents：工具和Chain框架
   - AutoGen：多Agent协作

3. **工具使用方法**：
   - 工具定义需要清晰的描述和模式
   - 工具调用需要健壮的执行和错误处理
   - 工具评估确保质量和可靠性

4. **Agent应用场景**：
   - 自动化复杂工作流程
   - 分解和求解复杂问题
   - 多Agent协作系统

---

## 习题与思考

1. Agent与传统聊天机器人的主要区别是什么？
2. 如何设计可靠的工具调用机制？
3. 多Agent系统中如何避免冲突和重复？
4. Agent系统的安全性如何保证？
5. 未来Agent的发展方向是什么？

## 参考资料

1. "AutoGPT: An Autonomous GPT-4 Agent" - GitHub
2. "BabyAGI: AI-powered Task Management System"
3. "LangChain Agents Documentation" - Harrison Chase
4. "AutoGen: Enabling Next-Gen LLM Applications" - Microsoft
5. "Tool Learning with Language Models" - Google Research