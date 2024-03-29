import os
import re
import time
from concurrent.futures import ThreadPoolExecutor

import attr
import openai
from joblib import Memory

memory = Memory("cache_folder", verbose=0)
# memory.clear(warn=False)  # Warning: Uncommenting this will bust the cache


# Set up your OpenAI API key
openai.api_key = os.environ["OPENAI_API_KEY"]


def prompt_completion(question, engine="davinci-instruct-beta", max_tokens=64, temperature=1.0, n=1, stop=None, return_top_n: int = None, ideal_length=None, collapse_newlines=True, throwaway_empties=True):
    if stop is None:
        stop = ["\n", "DONE"]
    start_time = time.perf_counter()
    prompt = f"{question} "
    response = openai.Completion.create(
        model=engine,  # "curie" is cheaper, "davinci" is good, there's also an option to get chatgpt on the website
        prompt=prompt,
        max_tokens=max_tokens,
        n=n,
        stop=stop,  # ["\n", "DONE"],  # ["\n", " Q:"],
        temperature=temperature,
    )
    if collapse_newlines:
        # Replace any number of newlines with a single newline, using regular expressions
        for i in range(len(response.choices)):
            response.choices[i].text = re.sub(r"\n+", "\n", response.choices[i].text)
    if return_top_n is None:
        answer = response.choices[0].text.strip()
    elif ideal_length is not None:
        answer = []
        ordered_choices = sorted(response.choices, key=lambda x: abs(sum(c.isalpha() for c in x.text)) - ideal_length)
        if throwaway_empties:
            ordered_choices = [x for x in ordered_choices if sum(c.isalpha() for c in x.text) > 0]
        for i in range(return_top_n):
            answer.append(ordered_choices[i].text.strip())
        print(f"Ordered choices: {ordered_choices}")
    else:  # TODO This doesn't really handle all cases
        answer = []
        for i in range(return_top_n):
            answer.append(response.choices[i].text.strip())
    # print(f"\tPROMPT: {question}\n\tANSWER: {answer}\n")
    duration = time.perf_counter() - start_time
    print(f"Duration: {duration:.2f} seconds: {answer}")
    return answer


@memory.cache
def prompt_completion_chat(question="", model="gpt-3.5-turbo", n=1, temperature=0.2, max_tokens=256, system_description="You are a helpful assistant.", messages=None) -> str:
    start_time = time.perf_counter()
    prompt = f"{question} "
    response = openai.ChatCompletion.create(
        # https://openai.com/blog/introducing-chatgpt-and-whisper-apis
        model=model,
        messages=messages if messages is not None else [
            {"role": "system", "content": system_description},
            {"role": "user", "content": prompt},
        ],
        max_tokens=max_tokens,
        temperature=temperature,
        n=n,
    )
    answers = []
    for i in range(n):
        ans = response.choices[i].message.content.strip()
        # Sometimes it quotes the response, so strip those off
        if ans[0] == "\"" and ans[-1] == "\"":
            ans = ans[1:-1]
        answers.append(ans)
    # print(f"\tPROMPT: {question}\n\tANSWER: {answer}\n")
    duration = time.perf_counter() - start_time
    short_answer = answers[0][:20].replace('\n', ' ')
    print(f"Duration: {duration:.2f} seconds: {short_answer}...")
    if n == 1:
        return answers[0]
    raise NotImplementedError("TODO: Return multiple answers")


@attr.s(auto_attribs=True)
class MultiThreadPrompting:
    max_num_threads: int = 10
    _executor: ThreadPoolExecutor = attr.ib(init=False, factory=lambda: None)

    def __attrs_post_init__(self):
        self._executor = ThreadPoolExecutor(max_workers=self.max_num_threads)

    def threaded_prompt_completion_chat(self, callback, *args, **kwargs):
        def wrapper():
            result = prompt_completion_chat(*args, **kwargs)
            callback(result)
        future = self._executor.submit(wrapper)

        # Uncomment the following line if you want to ensure that the task has completed.
        # future.result()

if __name__ == "__main__":
    # Callback function to be called once foo is done
    def my_callback(result):
        print("Result of foo:", result)

    mtp = MultiThreadPrompting(max_num_threads=5)

    for i in range(10):
        mtp.threaded_prompt_completion_chat(my_callback, i, i+1)
